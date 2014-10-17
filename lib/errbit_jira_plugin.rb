require 'errbit_jira_plugin/version'
require 'errbit_jira_plugin/error'
require 'errbit_jira_plugin/issue_tracker'
require 'errbit_jira_plugin/rails'

module ErrbitJiraPlugin
  def self.root
    File.expand_path '../..', __FILE__
  end
end

ErrbitPlugin::Registry.add_issue_tracker(ErrbitJiraPlugin::IssueTracker)
