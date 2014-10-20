require 'jira'

module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'jira'

    NOTE = 'Please configure Jira by entering your <strong>username</strong>, <strong>password</strong> and <strong>Jira install url</strong>.'

    FIELDS = [
      [:username, {
        :placeholder => "Your username"
      }],
      [:password, {
        :placeholder => "Your password"
      }],
      [:site, {
        :label       => "JIRA Install URL",
        :placeholder => "e.g. https://example.net"
      }],
      [:context_path, {
        :placeholder => "Context Path if any"
      }],
      [:project_id, {
        :label       => "Project ID",
        :placeholder => "Your project id to track issues"
      }]
    ]

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    def self.fields
      FIELDS
    end

    def self.body_template
      @body_template ||= ERB.new(File.read(
        File.join(
          ErrbitJiraPlugin.root, 'views', 'jira_issues_body.txt.erb'
        )
      ))
    end

    def configured?
      params['project_id'].present?
    end

    def errors
      errors = []
      if self.class.fields.detect {|f| params[f[0]].blank?}
        errors << [:base, 'You must specify your JIRA username, password, your site url, context and project id.']
      end
      errors
    end

    def comments_allowed?
      false
    end

    def create_issue(problem, reported_by = nil)
      begin
        #issue_title =  "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}",
        issue_title =  "#{problem.message.to_s.truncate(100)}",
        issue_description = self.class.body_template.result(binding).unpack('C*').pack('U*'),
          
        client = JIRA::Client.new({:username => params['username'], :password => params['password'], :site => params['site'], :auth_type => :basic, :context_path => ''})
        
        issue = client.Issue.build
        issue.save({"fields"=>{"summary"=>issue_title, "description"=>issue_description, "project"=>{"id"=>params['project_id']},"issuetype"=>{"id"=>"3"}}})

        problem.update_attributes(
          :issue_link => jira_url(issue),
          :issue_type => 'Bug'
        )

      rescue JIRA::HTTPError
        raise ErrbitJiraPlugin::IssueError, "Could not create an issue with Jira.  Please check your credentials."
      end
    end

    def jira_url(project_id)
      url = params['site'] << '/' unless params['site'].ends_with?('/')
      "#{url}browse/#{project_id}"
    end

    def url
      "https://www.atlassian.com/software"
    end
  end
end
