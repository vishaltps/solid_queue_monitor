# Roadmap

This document tracks planned features for solid_queue_monitor, comparing with other solutions like `solid-queue-dashboard` and `mission_control-jobs`.

## High Priority - Core Functionality Gaps

| Feature | solid-queue-dashboard | mission_control-jobs | Impact | Status |
|---------|:---------------------:|:--------------------:|--------|:------:|
| Auto-refresh | ✓ | - | High - Real-time monitoring essential for ops | ✅ Done (v0.4.0) |
| Charts/Visualizations | ✓ | - | High - Visual trends are compelling | ⬚ Planned |
| Pause/Unpause Queues | - | ✓ | High - Critical for production incident response | ✅ Done (v0.5.0) |
| Worker Monitoring | - | ✓ | High - See which workers are processing what | ⬚ Planned |
| Dead Process Detection | ✓ | - | High - Identify stuck/zombie processes | ⬚ Planned |
| Execution History | ✓ | - | Medium - Job audit trail | ⬚ Planned |
| Failure Rate Tracking | ✓ | - | Medium - Trends over time | ⬚ Planned |

## Medium Priority - Power Features

| Feature | Description | Status |
|---------|-------------|:------:|
| Sensitive Argument Masking | Filter passwords/tokens from job arguments display | ⬚ Planned |
| Backtrace Cleaner | Remove framework noise from error backtraces | ⬚ Planned |
| Manual Job Triggering | Enqueue a job directly from the dashboard | ⬚ Planned |
| Cancel Running Jobs | Stop long-running jobs | ⬚ Planned |
| Search/Full-text Search | Better search across all job data | ⬚ Planned |
| Sorting Options | Sort by various columns | ⬚ Planned |
| Job Details Page | Dedicated page for single job with full context | ⬚ Planned |

## Lower Priority - Enterprise Features

| Feature | Description | Status |
|---------|-------------|:------:|
| Multi-app Support | Manage multiple apps from one dashboard | ⬚ Planned |
| Multi-database Support | Connect to different Solid Queue databases | ⬚ Planned |
| Console Helpers | Ruby API for scripting job operations | ⬚ Planned |
| Bulk Operation Throttling | Delay between bulk ops to prevent DB overload | ⬚ Planned |
| Export Jobs (CSV/JSON) | Download job data for analysis | ⬚ Planned |
| Webhooks/Notifications | Alert on failures via Slack/email | ⬚ Planned |
| API Endpoints (JSON) | Return JSON for custom integrations | ⬚ Planned |
| Dark Mode Toggle | User preference for theme | ⬚ Planned |

---

## Legend

- ✅ Done - Feature implemented
- 🚧 In Progress - Currently being worked on
- ⬚ Planned - Not yet started
