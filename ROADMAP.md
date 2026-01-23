# Roadmap

This document tracks planned features for solid_queue_monitor, comparing with other solutions like `solid-queue-dashboard` and `mission_control-jobs`.

## Target: v1.0.0 (Stable Release)

### High Priority - Core Functionality Gaps

| Feature | solid-queue-dashboard | mission_control-jobs | Impact | Status |
|---------|:---------------------:|:--------------------:|--------|:------:|
| Auto-refresh | ✓ | - | High - Real-time monitoring essential for ops | ✅ Done (v0.4.0) |
| Charts/Visualizations | ✓ | - | High - Visual trends are compelling | ✅ Done (v0.6.0) |
| Pause/Unpause Queues | - | ✓ | High - Critical for production incident response | ✅ Done (v0.5.0) |
| Dark Mode Toggle | - | - | High - User preference for theme | ✅ Done (v0.6.0) |
| Worker Monitoring | - | ✓ | High - See which workers are processing what | ✅ Done |
| Dead Process Detection | ✓ | - | High - Identify stuck/zombie processes | ✅ Done |

### Medium Priority - Power Features

| Feature | Description | Status |
|---------|-------------|:------:|
| Job Details Page | Dedicated page for single job with full context | ✅ Done |
| Search/Full-text Search | Better search across all job data | ⬚ Planned |
| Sorting Options | Sort by various columns | ⬚ Planned |
| Sensitive Argument Masking | Filter passwords/tokens from job arguments display | ⬚ Planned |
| Backtrace Cleaner | Remove framework noise from error backtraces | ⬚ Planned |
| Manual Job Triggering | Enqueue a job directly from the dashboard | ⬚ Planned |
| Cancel Running Jobs | Stop long-running jobs | ⬚ Planned |

### Lower Priority - Enterprise Features (Post 1.0)

| Feature | Description | Status |
|---------|-------------|:------:|
| Multi-app Support | Manage multiple apps from one dashboard | ⬚ Planned |
| Multi-database Support | Connect to different Solid Queue databases | ⬚ Planned |
| Console Helpers | Ruby API for scripting job operations | ⬚ Planned |
| Bulk Operation Throttling | Delay between bulk ops to prevent DB overload | ⬚ Planned |
| Export Jobs (CSV/JSON) | Download job data for analysis | ⬚ Planned |
| Webhooks/Notifications | Alert on failures via Slack/email | ⬚ Planned |
| API Endpoints (JSON) | Return JSON for custom integrations | ⬚ Planned |

---

## Suggested v1.0.0 Scope

For a stable 1.0.0 release, all high-priority features have been completed:

1. ~~**Dead Process Detection** - Prune button for stale/dead workers~~ ✅
2. ~~**Worker Monitoring** - See which workers are processing what~~ ✅
3. ~~**Charts/Visualizations** - Visual trends for job activity~~ ✅

Optional but valuable for 1.0.0:
- **Sorting Options** - Click column headers to sort

---

## Legend

- ✅ Done - Feature implemented
- 🚧 In Progress - Currently being worked on
- ⬚ Planned - Not yet started
