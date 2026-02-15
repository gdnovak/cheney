# Task File Schema (`coordination/tasks/*.yaml`)

Required keys:

1. `id`
2. `title`
3. `owner`
4. `created_at`
5. `status`
6. `risk_class`
7. `requires_approval`
8. `requires_egpu_ready`
9. `prechecks`
10. `success_criteria`
11. `rollback`
12. `commands`
13. `report_path`

Valid `status`:

- `queued`
- `claimed`
- `running`
- `done`
- `failed`
- `blocked`
