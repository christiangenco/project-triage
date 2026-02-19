# project-triage

Sinatra web dashboard for triaging projects via AI scanning.

```bash
cd ~/tools/project-triage
ruby app.rb          # starts on http://localhost:4567
```

## Endpoints

```
GET    /                          Web UI
PATCH  /projects/:id/status       Update status: {"status": "starred|hidden|inbox"}
PATCH  /projects/:id/notes        Update notes: {"notes": "..."}
POST   /projects/:id/scan         Trigger AI scan (SSH + pi CLI)
POST   /projects/batch-scan       Queue batch scan: {"ids": [...]}
```

Data is stored in `projects.json` (gitignored — sync via `~/tools/sync.sh creds`).
