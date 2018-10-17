require './google-sheets-client'
require './lib/tasklist-data'
require 'pry-byebug'
require 'linkeddata'
require 'bson'
require 'digest'
require 'fileutils'
require 'digest/md5'

class TasklistSerializer
  FOAF = RDF::Vocab::FOAF
  DC = RDF::Vocab::DC
  RDFS = RDF::Vocab::RDFS
  ADMS = RDF::Vocabulary.new("http://www.w3.org/ns/adms#")
  MU = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/core/")
  EXT = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/ext/")
  SKOS = RDF::Vocab::SKOS
  TOEZICHT = RDF::Vocabulary.new("http://mu.semte.ch/vocabularies/ext/supervision/")

  BASE_URI = 'http://data.lblod.info/id/%{resource}/%{id}'

  def initialize(output_folder)
    @google_client = GoogleSheetsClient.new()
    @tasklist_data = TasklistData.new(@google_client)
    @graph = RDF::Graph.new
    @output_folder = output_folder
  end

  def serialize
    tasklists_map = create_tasklists(@tasklist_data.tasklists)
    tasks_map = create_tasks(@tasklist_data.tasks)
    link_parent_tasks_in_tasklist(tasklists_map, tasks_map, @tasklist_data.tasks)
    link_task_with_subtask(tasks_map, @tasklist_data.tasks)
    write_ttl_to_file(@output_folder, 'tasklists', @graph)
  end

  def create_tasklists(tasklists)
    tasklists_map = {}
    tasklists.each do |tasklist|
      tasklists_map.merge!(create_tasklist(tasklist))
    end
    tasklists_map
  end

  def create_tasklist(tasklist)
    salt = "08fc470e-f1bb-4903-a284-ca624d6ec6bb"
    uuid = hash(tasklist["id"].to_s + ":" + salt)
    subject = RDF::URI(BASE_URI % {:resource => "tasklists", :id => uuid})

    @graph << RDF.Statement(subject, RDF.type, EXT["Tasklist"])
    @graph << RDF.Statement(subject, MU.uuid, uuid)
    @graph << RDF.Statement(subject, EXT["tasklistName"], tasklist["name"])

    { tasklist["id"] => subject }
  end

  def create_tasks(tasks)
    tasks_map = {}
    tasks.each do |task|
      tasks_map.merge!(create_task(task))
    end
    tasks_map
  end

  def create_task(task)
    salt = "3e3bfa9f-b25d-415e-9d77-0d5d8a3f40e2"
    uuid = hash(task["id"].to_s + ":" + salt)
    subject = RDF::URI(BASE_URI % {:resource => "tasks", :id => uuid})

    @graph << RDF.Statement(subject, RDF.type, EXT["Task"])
    @graph << RDF.Statement(subject, MU.uuid, uuid)
    @graph << RDF.Statement(subject, EXT["taskTitle"], task["title"])
    @graph << RDF.Statement(subject, EXT["taskDescription"], task["description"])
    @graph << RDF.Statement(subject, EXT["taskPriority"], task["priority"])

    { task["id"] => subject }
  end

  def link_parent_tasks_in_tasklist(tasklist_map, tasks_map, tasks)
    tasks.each do |task|
      if(!task['tasklist_id'])
        next
      end
      @graph << RDF.Statement(tasklist_map[task['tasklist_id']], EXT["tasklistTask"], tasks_map[task["id"]])
    end
  end

  def link_task_with_subtask(tasks_map, tasks)
    tasks.each do |task|
      if(!task['parent'])
        next
      end
      @graph << RDF.Statement(tasks_map[task['parent']], EXT["taskChild"], tasks_map[task["id"]])
    end
  end

  def write_ttl_to_file(folder, file, graph, timestamp_ttl = false)
    file_path = File.join(folder, file + '.ttl')
    if timestamp_ttl
      file_path = File.join(folder, file + "_" + DateTime.now.strftime("%Y-%m-%d_%H%M%S") + ".ttl")
    end
    RDF::Writer.open(file_path) { |writer| writer << graph }
  end

  def hash(str)
    return Digest::SHA256.hexdigest str
  end
end

serializer = TasklistSerializer.new("output")
serializer.serialize
