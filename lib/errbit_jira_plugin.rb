require 'errbit_jira_plugin/version'
require 'errbit_jira_plugin/error'
require 'errbit_jira_plugin/issue_tracker'
require 'errbit_jira_plugin/rails'

module ErrbitJiraPlugin
  def self.root
    File.expand_path '../..', __FILE__
  end
  
  def self.read_static_file(file)
    File.read(File.join(self.root, 'vendor/assets/images', file))
  end
end

ErrbitPlugin::Registry.add_issue_tracker(ErrbitJiraPlugin::IssueTracker)
