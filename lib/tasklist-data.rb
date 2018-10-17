require 'json'

class TasklistData

  def initialize(google_client)
    @client = google_client
  end

  def tasklists
    tasklist_data = get_tasklist_data
    tasklists = generate_tasklists(tasklist_data)
    tasklists
  end

  def tasks
    tasklist_data = get_tasklist_data
    tasks = tasklist_data.map{ |t| generate_task(t) }
    tasks
  end

  def get_tasklist_data
    file_id = '17gu6AC6qsjjK4NtSdSGJCM_kucnR6sHE8su_WClNVXs'
    inputs_tab = "taken"
    @client.get_spreadsheet_tab_values(file_id, inputs_tab)
  end

  def generate_tasklists(tasklist_data)
    tasklists = tasklist_data.uniq { |row| row["id takenlijst"] }
    formatted_tasklists = []
    tasklists.each do |tasklist|
      tasklist_hash = {}
      tasklist_hash["id"] = tasklist["id takenlijst"].to_i
      tasklist_hash["name"] = tasklist["naam takenlijst"]

      formatted_tasklists << tasklist_hash
    end
    formatted_tasklists
  end

  def generate_task(task_data)
    # id takenlijst   naam takenlijst taak id   parent taak   titel taak  taakbeschrijving  prioriteit
    task_hash = {}
    task_hash["title"] = task_data["titel taak"]
    task_hash["description"] = task_data["taakbeschrijving"]
    task_hash["priority"] = task_data["priorteit"].to_i
    task_hash["id"] = task_data["taak id"]
    task_hash["parent"] = task_data["parent taak"].length != 0 ? task_data["parent taak"] : nil
    task_hash["tasklist_id"] = task_data["parent taak"].length != 0 ? nil : task_data["id"] # basically the parent where it belongs to
    task_hash
  end

end
