# project-triage

Sinatra web dashboard for triaging a large collection of projects. Uses AI (via `pi` CLI over SSH) to scan and summarize each project.

## Setup

```bash
bundle install
```

Create a `projects.json` file (gitignored) with an array of project entries:

```json
[
  {
    "id": "my-project",
    "dir_name": "my-project",
    "path": "hostname:~/projects/my-project/",
    "remote_path": "/home/user/projects/my-project/",
    "status": "inbox"
  }
]
```

Scanning requires SSH access to the remote host and `pi` installed there.

## Usage

```bash
ruby app.rb
# or
bin/run.sh
```

Open `http://localhost:4567`. The dashboard lets you:
- View all projects with their AI-generated summaries
- Star, hide, or triage projects
- Add notes to projects
- Trigger AI scans (SSH → `pi` → Claude Haiku) to auto-fill name, summary, tech stack, etc.
