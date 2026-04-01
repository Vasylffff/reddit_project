"""
detect_flow_deviation.py  —  Reddit news pulse detector

Compares the current state of posts in each topic/subreddit against their
historical baseline. Flags when something unusual is happening.

Examples:
    python detect_flow_deviation.py
    python detect_flow_deviation.py --topic war_geopolitics
    python detect_flow_deviation.py --hours 6
    python detect_flow_deviation.py --threshold 1.5
"""

import argparse
import collections
import csv
import os
import sys

SNAPSHOTS_PATH  = "data/history/reddit/post_snapshots.csv"
PREDICTION_PATH = "data/models/reddit/prediction_next_hour.csv"

STATES       = ["surging", "alive", "cooling", "dying", "dead"]
VALID_STATES = set(STATES)

C = {
    "surging":  "\033[92m",
    "alive":    "\033[96m",
    "cooling":  "\033[93m",
    "dying":    "\033[33m",
    "dead":     "\033[91m",
    "alert_hi": "\033[91m",
    "alert_lo": "\033[94m",
    "normal":   "\033[92m",
    "bold":     "\033[1m",
    "dim":      "\033[2m",
    "reset":    "\033[0m",
}

def col(key, text=None):
    return C.get(key, "") + (text or key) + C["reset"]


# ---------------------------------------------------------------------------
# Load
# ---------------------------------------------------------------------------

def load_data():
    for p in (SNAPSHOTS_PATH, PREDICTION_PATH):
        if not os.path.exists(p):
            sys.exit(f"ERROR: {p} not found.")

    post_meta = {}
    with open(PREDICTION_PATH, encoding="utf-8", errors="replace") as f:
        for row in csv.DictReader(f):
            pid = row["post_id"]
            if pid not in post_meta and row.get("content_topic_primary"):
                post_meta[pid] = {
                    "topic":    row["content_topic_primary"],
                    "subreddit": row["subreddit"],
                }

    snap_state = {}
    snap_rows  = []
    with open(SNAPSHOTS_PATH, encoding="utf-8", errors="replace") as f:
        for row in csv.DictReader(f):
            state = row.get("activity_state", "").strip()
            if state in VALID_STATES:
                snap_state[(row["snapshot_id"], row["post_id"])] = state
            snap_rows.append(row)

    return snap_rows, snap_state, post_meta


# ---------------------------------------------------------------------------
# Compute baselines and current state
# ---------------------------------------------------------------------------

def compute_baselines(snap_rows, snap_state, post_meta):
    """
    Historical average surge+alive rate per (topic, subreddit).
    Excludes the most recent 3 hours so it's a true baseline, not
    inflated/deflated by the current window we're comparing against.
    """
    times = [r["snapshot_time_utc"] for r in snap_rows if r.get("snapshot_time_utc")]
    if not times:
        return {}
    latest = max(times)
    # Exclude last 3 hours from baseline (not just 1 hour)
    cutoff = latest[:13]
    cutoff_hours = sorted(set(t[:13] for t in times))
    if len(cutoff_hours) >= 4:
        cutoff = cutoff_hours[-3]  # exclude last 3 collection hours

    counts = collections.defaultdict(lambda: collections.Counter())
    for row in snap_rows:
        t = row.get("snapshot_time_utc", "")
        if not t or t[:13] >= cutoff:
            continue
        pid = row["post_id"]
        if pid not in post_meta:
            continue
        state = snap_state.get((row["snapshot_id"], pid))
        if not state:
            continue
        key = (post_meta[pid]["topic"], post_meta[pid]["subreddit"])
        counts[key][state] += 1

    baselines = {}
    for key, c in counts.items():
        total = sum(c.values())
        if total < 10:
            continue
        baselines[key] = {
            "surge_alive_rate": (c.get("surging", 0) + c.get("alive", 0)) / total,
            "surge_rate":       c.get("surging", 0) / total,
            "dead_rate":        c.get("dead", 0) / total,
            "state_dist":       {s: c.get(s, 0) / total for s in STATES},
            "n":                total,
        }
    return baselines


def compute_current(snap_rows, snap_state, post_meta, hours_window=3):
    """
    Current state distribution per (topic, subreddit) from the last N hours.
    """
    times = [r["snapshot_time_utc"] for r in snap_rows if r.get("snapshot_time_utc")]
    if not times:
        return {}
    latest  = max(times)
    cutoff  = latest[:13]  # only take snapshots from the latest hour window

    counts = collections.defaultdict(lambda: collections.Counter())
    for row in snap_rows:
        t = row.get("snapshot_time_utc", "")
        if not t or t[:13] < cutoff:
            continue
        pid = row["post_id"]
        if pid not in post_meta:
            continue
        state = snap_state.get((row["snapshot_id"], pid))
        if not state:
            continue
        key = (post_meta[pid]["topic"], post_meta[pid]["subreddit"])
        counts[key][state] += 1

    current = {}
    for key, c in counts.items():
        total = sum(c.values())
        if total < 3:
            continue
        current[key] = {
            "surge_alive_rate": (c.get("surging", 0) + c.get("alive", 0)) / total,
            "surge_rate":       c.get("surging", 0) / total,
            "dead_rate":        c.get("dead", 0) / total,
            "state_dist":       {s: c.get(s, 0) / total for s in STATES},
            "n":                total,
        }
    return current


# ---------------------------------------------------------------------------
# Cross-subreddit signals
# ---------------------------------------------------------------------------

def detect_cross_subreddit(deviations, threshold=1.4):
    """
    Find topics that are deviating in the SAME direction across multiple
    subreddits simultaneously — much stronger signal than a single subreddit.
    """
    by_topic = collections.defaultdict(list)
    for d in deviations:
        by_topic[d["topic"]].append(d)

    cross_signals = []
    for topic, devs in by_topic.items():
        surging_subs = [d["subreddit"] for d in devs
                        if d["surge_ratio"] >= threshold]
        quiet_subs   = [d["subreddit"] for d in devs
                        if d["alive_ratio"] <= 1 / threshold]

        if len(surging_subs) >= 2:
            avg_mag = sum(d["surge_ratio"] for d in devs
                         if d["subreddit"] in surging_subs) / len(surging_subs)
            cross_signals.append({
                "topic":     topic,
                "kind":      "MULTI-SUB SURGE",
                "subreddits": surging_subs,
                "magnitude": avg_mag,
                "alert":     "alert_hi",
            })
        if len(quiet_subs) >= 2:
            avg_mag = sum(1 / max(d["alive_ratio"], 0.01) for d in devs
                         if d["subreddit"] in quiet_subs) / len(quiet_subs)
            cross_signals.append({
                "topic":     topic,
                "kind":      "MULTI-SUB QUIET",
                "subreddits": quiet_subs,
                "magnitude": avg_mag,
                "alert":     "alert_lo",
            })

    cross_signals.sort(key=lambda x: -x["magnitude"])
    return cross_signals


# ---------------------------------------------------------------------------
# History logging
# ---------------------------------------------------------------------------

HISTORY_PATH = "data/history/reddit/deviation_log.csv"

def save_to_history(deviations, cross_signals, latest_time):
    """Append this run's deviations to the history log."""
    os.makedirs(os.path.dirname(HISTORY_PATH), exist_ok=True)
    file_exists = os.path.exists(HISTORY_PATH)

    with open(HISTORY_PATH, "a", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        if not file_exists:
            writer.writerow([
                "timestamp", "topic", "subreddit", "kind", "magnitude",
                "surge_ratio", "alive_ratio", "dead_ratio",
                "current_surge_rate", "current_alive_rate", "current_dead_rate",
                "baseline_surge_alive_rate", "cross_subreddit"
            ])
        for d in deviations:
            writer.writerow([
                latest_time[:16],
                d["topic"], d["subreddit"], d["kind"],
                round(d["magnitude"], 2),
                round(d["surge_ratio"], 2),
                round(d["alive_ratio"], 2),
                round(d["dead_ratio"], 2),
                round(d["current"]["surge_rate"], 3),
                round(d["current"]["surge_alive_rate"], 3),
                round(d["current"]["dead_rate"], 3),
                round(d["baseline"]["surge_alive_rate"], 3),
                0,
            ])
        for cs in cross_signals:
            writer.writerow([
                latest_time[:16],
                cs["topic"], "+".join(cs["subreddits"]), cs["kind"],
                round(cs["magnitude"], 2),
                "", "", "", "", "", "", "", 1,
            ])


# ---------------------------------------------------------------------------
# Detect deviations
# ---------------------------------------------------------------------------

def detect_deviations(baselines, current, threshold=1.4):
    """
    Compare current vs baseline.
    Returns list of deviations sorted by magnitude.
    """
    deviations = []

    for key, curr in current.items():
        if key not in baselines:
            continue
        base = baselines[key]

        surge_ratio = (curr["surge_rate"] / base["surge_rate"]
                       if base["surge_rate"] > 0.01 else 1.0)
        dead_ratio  = (curr["dead_rate"]  / base["dead_rate"]
                       if base["dead_rate"]  > 0.01 else 1.0)
        alive_ratio = (curr["surge_alive_rate"] / base["surge_alive_rate"]
                       if base["surge_alive_rate"] > 0.01 else 1.0)

        # Classify the deviation
        if surge_ratio >= threshold * 1.5:
            kind      = "SURGE SPIKE"
            magnitude = surge_ratio
            alert     = "alert_hi"
            detail    = f"surge rate {curr['surge_rate']:.0%} vs baseline {base['surge_rate']:.0%}"
        elif surge_ratio >= threshold:
            kind      = "elevated activity"
            magnitude = surge_ratio
            alert     = "alert_hi"
            detail    = f"surge rate {curr['surge_rate']:.0%} vs baseline {base['surge_rate']:.0%}"
        elif alive_ratio <= 1 / threshold:
            kind      = "unusually quiet"
            magnitude = 1 / max(alive_ratio, 0.01)
            alert     = "alert_lo"
            detail    = f"active rate {curr['surge_alive_rate']:.0%} vs baseline {base['surge_alive_rate']:.0%}"
        elif dead_ratio >= threshold * 1.5:
            kind      = "mass die-off"
            magnitude = dead_ratio
            alert     = "alert_lo"
            detail    = f"dead rate {curr['dead_rate']:.0%} vs baseline {base['dead_rate']:.0%}"
        else:
            kind      = "normal"
            magnitude = 1.0
            alert     = "normal"
            detail    = f"active rate {curr['surge_alive_rate']:.0%} vs baseline {base['surge_alive_rate']:.0%}"

        deviations.append({
            "topic":       key[0],
            "subreddit":   key[1],
            "kind":        kind,
            "magnitude":   magnitude,
            "alert":       alert,
            "detail":      detail,
            "surge_ratio": surge_ratio,
            "alive_ratio": alive_ratio,
            "dead_ratio":  dead_ratio,
            "current":     curr,
            "baseline":    base,
        })

    # Sort: alerts first, then by magnitude
    deviations.sort(key=lambda d: (d["kind"] == "normal", -d["magnitude"]))
    return deviations


# ---------------------------------------------------------------------------
# Display
# ---------------------------------------------------------------------------

def print_report(deviations, latest_time, threshold):
    print()
    print(C["bold"] + "=" * 72 + C["reset"])
    print(C["bold"] + "  REDDIT NEWS PULSE  —  deviation detector" + C["reset"])
    print(f"  As of: {latest_time[:16]}  |  threshold: x{threshold}")
    print("=" * 72)

    alerts   = [d for d in deviations if d["kind"] != "normal"]
    normals  = [d for d in deviations if d["kind"] == "normal"]

    if not alerts:
        print(f"\n  {col('normal', 'All topics within normal range.')}  Nothing unusual detected.\n")
    else:
        print(f"\n  {col('alert_hi', str(len(alerts)))} deviation(s) detected:\n")
        for d in alerts:
            topic  = d["topic"]
            sub    = d["subreddit"]
            kind   = d["kind"]
            alert  = d["alert"]
            mag    = d["magnitude"]
            detail = d["detail"]

            # Bar showing current vs baseline state dist
            curr_dist = d["current"]["state_dist"]
            bar = ""
            for s in STATES:
                filled = round(curr_dist.get(s, 0) * 20)
                bar   += C.get(s, "") + "#" * filled + C["reset"]
            bar = "[" + bar + "]"

            print(f"  {col(alert, f'[{kind.upper()}]'):<40}  x{mag:.1f}")
            print(f"  {C['bold']}{topic:<28}{C['reset']}  r/{sub}")
            print(f"  {detail}")
            print(f"  {bar}  ", end="")
            for s in STATES:
                p = curr_dist.get(s, 0)
                print(f" {C.get(s,'')}{s[:4]}={p:.0%}{C['reset']}", end="")
            print("\n")

    # Normal topics compact summary
    if normals:
        print(f"  {C['dim']}Normal activity ({len(normals)} topic/subreddit combos):{C['reset']}")
        for d in normals:
            curr = d["current"]
            sa   = curr["surge_alive_rate"]
            print(f"  {C['dim']}{d['topic']:<28}  r/{d['subreddit']:<12}"
                  f"  active={sa:.0%}  ({d['detail']}){C['reset']}")

    print()
    print("=" * 72)
    print()


def print_cross_signals(cross_signals):
    if not cross_signals:
        return
    print(C["bold"] + "  CROSS-SUBREDDIT SIGNALS" + C["reset"])
    print("  (same topic deviating across multiple subreddits simultaneously)\n")
    for cs in cross_signals:
        alert = cs["alert"]
        subs  = ", ".join(f"r/{s}" for s in cs["subreddits"])
        kind_label = cs["kind"]
        print(f"  {col(alert, f'[{kind_label}]'):<40}  x{cs['magnitude']:.1f}")
        print(f"  {C['bold']}{cs['topic']}{C['reset']}  across  {subs}\n")
    print("=" * 72)
    print()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Reddit news pulse / deviation detector")
    parser.add_argument("--topic",     default=None, help="Filter to one topic")
    parser.add_argument("--hours",     type=int, default=3,
                        help="Window for 'current' state (default 3)")
    parser.add_argument("--threshold", type=float, default=1.4,
                        help="Multiplier to flag as deviation (default 1.4)")
    args = parser.parse_args()

    print("Loading data...")
    snap_rows, snap_state, post_meta = load_data()

    times      = [r["snapshot_time_utc"] for r in snap_rows if r.get("snapshot_time_utc")]
    latest_time = max(times) if times else "unknown"

    print("Computing baselines...")
    baselines = compute_baselines(snap_rows, snap_state, post_meta)
    print(f"  {len(baselines)} topic/subreddit baselines computed")

    print("Computing current state...")
    current = compute_current(snap_rows, snap_state, post_meta, args.hours)
    print(f"  {len(current)} topic/subreddit groups in current window")

    if args.topic:
        baselines = {k: v for k, v in baselines.items() if k[0] == args.topic}
        current   = {k: v for k, v in current.items()   if k[0] == args.topic}

    deviations    = detect_deviations(baselines, current, args.threshold)
    cross_signals = detect_cross_subreddit(deviations, args.threshold)

    print_report(deviations, latest_time, args.threshold)
    print_cross_signals(cross_signals)

    save_to_history(deviations, cross_signals, latest_time)
    print(f"  History logged to {HISTORY_PATH}\n")


if __name__ == "__main__":
    main()
