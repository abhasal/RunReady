# RunReady — Race Readiness Algorithm

## Overview

The prediction engine uses a **conservative, rule-based scoring model**. It is not ML or AI. Every score is deterministic and explainable. The goal is *safe* readiness — not peak performance prediction.

---

## Inputs

The engine receives all stored `RunWorkout` objects and groups them into **training windows**:

| Window | Used for |
|--------|----------|
| Last 2 weeks | Recency check |
| Last 4 weeks | Long run + volume baseline |
| Last 8 weeks | Frequency consistency |
| Last 12 weeks | Overall training commitment |

---

## Scoring (per race distance)

Each distance receives a composite score from **0 – 100**, computed as a weighted average of four independent factors.

### Factor 1: Long Run (weight 35%)

**Rationale:** The single best predictor of race readiness is whether you've run at least 60–80% of the target distance in recent training.

```
long_run_score = min(longest_run_in_4_weeks / required_long_run, 1.0)
```

### Factor 2: Weekly Volume (weight 30%)

**Rationale:** Total volume over 4 weeks indicates training density and aerobic base.

```
volume_score = min(avg_weekly_meters_last_4_weeks / required_weekly_avg, 1.0)
```

### Factor 3: Run Frequency (weight 20%)

**Rationale:** Running more days per week builds aerobic efficiency and reduces injury risk from any single long run.

```
frequency_score = min(avg_runs_per_week_last_8_weeks / required_runs_per_week, 1.0)
```

### Factor 4: Consistency (weight 15%)

**Rationale:** 12-week commitment signals the runner has been building fitness progressively, not just cramming.

```
consistency_score = min(active_weeks_in_last_12 / required_active_weeks, 1.0)
```

### Composite

```
composite = (long_run_score × 0.35) + (volume_score × 0.30) + (frequency_score × 0.20) + (consistency_score × 0.15)
final_score = composite × 100
```

---

## Safety Cap

If the runner's **last-week volume is more than 40% higher** than their 3-week trailing average, the composite is capped at 0.70 (score 70). This penalizes training spikes that commonly precede injury.

---

## Readiness Tiers

| Score | Tier | Meaning |
|-------|------|---------|
| ≥ 85  | Safely Ready | Conservative "you can race this" |
| 65–84 | Nearly Ready | Close — a few more weeks |
| 40–64 | Build Base | Need meaningful training progress |
| < 40  | Not Ready | Too early |

---

## Race Distance Requirements

| Distance | Long Run (4 wks) | Weekly Avg (4 wks) | Runs/Week (8 wks) | Active Weeks (12) |
|----------|------------------|--------------------|-------------------|-------------------|
| 5K       | 4 km             | 8 km               | 2.0               | 4                 |
| 10K      | 8 km             | 20 km              | 3.0               | 6                 |
| 15K      | 11 km            | 24 km              | 3.0               | 8                 |
| Half     | 14.5 km          | 32 km              | 4.0               | 9                 |
| Marathon | 29 km            | 56 km              | 5.0               | 11                |

All thresholds are **conservative** — typical race training plans target higher volumes.

---

## Recommendation

The `recommendedDistance` is the **highest distance** with tier `safelyReady`. If no distance qualifies, the recommendation is `nil` with a prompt to build base training.

---

## Limitations & Future Work

- Does not account for running pace (a 6-min/km runner and a 4-min/km runner with same volume have equal scores)
- Heart rate data is collected but not yet factored into the score
- No periodization or taper detection
- Injury history is not tracked
- Future versions can weight pace-based stress load (e.g., Training Stress Score)

---

## Disclaimer

This algorithm provides training guidance only. It is not medical advice. Always consult a healthcare professional or certified running coach before making race or training decisions, especially if you have health conditions.
