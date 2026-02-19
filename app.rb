require "sinatra"
require "sinatra/reloader" if development?
require "json"
require "shellwords"
require "open3"

DATA_FILE = File.join(__dir__, "projects.json")
LOCK = Mutex.new
$projects = JSON.parse(File.read(DATA_FILE))

def save_projects
  File.write(DATA_FILE, JSON.pretty_generate($projects))
end

def find_project(id)
  $projects.find { |p| p["id"] == id }
end

get "/" do
  @projects = LOCK.synchronize { $projects.dup }
  erb :index
end

# Update status (starred/hidden/inbox) for a project
patch "/projects/:id/status" do
  content_type :json
  data = JSON.parse(request.body.read)
  LOCK.synchronize do
    project = find_project(params[:id])
    halt 404, { error: "not found" }.to_json unless project
    project["status"] = data["status"]
    save_projects
    { ok: true, status: project["status"] }.to_json
  end
end

# Update notes for a project
patch "/projects/:id/notes" do
  content_type :json
  data = JSON.parse(request.body.read)
  LOCK.synchronize do
    project = find_project(params[:id])
    halt 404, { error: "not found" }.to_json unless project
    project["notes"] = data["notes"]
    save_projects
    { ok: true }.to_json
  end
end

# Trigger a scan of a single project
post "/projects/:id/scan" do
  content_type :json

  # Grab remote_path under lock, then release for the long SSH call
  remote_path = LOCK.synchronize do
    project = find_project(params[:id])
    halt 404, { error: "not found" }.to_json unless project
    project["remote_path"]
  end

  prompt = 'Examine this project (look at README, package.json, top-level files, src/ structure — stay shallow). Respond with ONLY a raw JSON object, no markdown fences, no explanation. Fields: name (string), summary (one sentence), tech_stack (string), completeness (1-5 integer), target_audience (string), category (string)'

  cmd = [
    "ssh", "max.local",
    "export PATH=\"$HOME/.nvm/versions/node/v20.10.0/bin:$PATH\" && " \
    "cd #{Shellwords.escape(remote_path)} && " \
    "pi --provider anthropic --model claude-haiku-4-5 " \
    "--no-session --no-extensions --no-skills --no-prompt-templates --no-themes " \
    "--thinking off --tools read,ls " \
    "-p #{Shellwords.escape(prompt)}"
  ]

  stdout, stderr, exit_status = Open3.capture3(*cmd, stdin_data: "")

  # Strip markdown fences
  raw = stdout.lines.reject { |l| l.strip.start_with?("```") }.join.strip

  begin
    result = JSON.parse(raw)

    # Re-acquire lock to apply scan results to current in-memory state
    LOCK.synchronize do
      project = find_project(params[:id])
      halt 404, { error: "not found" }.to_json unless project
      project["name"] = result["name"] || ""
      project["summary"] = result["summary"] || ""
      project["tech_stack"] = result["tech_stack"] || ""
      project["completeness"] = result["completeness"]
      project["target_audience"] = result["target_audience"] || ""
      project["category"] = result["category"] || ""
      project["scanned"] = true
      project["error"] = ""
      save_projects
      project.to_json
    end
  rescue JSON::ParserError => e
    LOCK.synchronize do
      project = find_project(params[:id])
      if project
        project["scanned"] = false
        project["error"] = "Parse error: #{raw[0..200]}"
        save_projects
      end
    end
    halt 422, { error: "Failed to parse LLM response", raw: raw[0..500] }.to_json
  end
end

# Batch scan: trigger scan for multiple projects
post "/projects/batch-scan" do
  content_type :json
  data = JSON.parse(request.body.read)
  ids = data["ids"] || []
  { queued: ids.length, ids: ids }.to_json
end
