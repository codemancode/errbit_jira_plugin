require 'jira'

module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'jira'

    NOTE = 'Please configure Jira by entering the information below.'

    FIELDS = [
        [:base_url, {
            :label => 'Jira URL without trailing slash',
            :placeholder => 'https://jira.example.org'
        }],
        [:context_path, {
            :optional => true,
            :label => 'Context Path (Just "/" if empty otherwise with leading slash)',
            :placeholder => "/jira"
        }],
        [:username, {
            :label => 'Username',
            :placeholder => 'johndoe'
        }],
        [:password, {
            :label => 'Password',
            :placeholder => 'p@assW0rd'
        }],
        [:project_id, {
            :label => 'Project Key',
            :placeholder => 'The project Key where the issue will be created'
        }],
        [:issue_priority, {
            :label => 'Priority',
            :placeholder => 'Normal'
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
      if self.class.fields.detect {|f| params[f[0]].blank? && !f[1][:optional]}
        errors << [:base, 'You must specify all non optional values!']
      end
      errors
    end

    def comments_allowed?
      false
    end

    def client
      options = {
        :username => params['username'],
        :password => params['password'],
        :site => params['base_url'],
        :auth_type => :basic,
        :context_path => (params['context_path'] == '/') ? params['context_path'] = '' : params['context_path']
      }
      JIRA::Client.new(options)
    end

    def create_issue(problem, reported_by = nil)
      begin
        issue_title =  "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}".delete!("\n")
        issue_description = self.class.body_template.result(binding).unpack('C*').pack('U*')
        issue = {"fields"=>{"summary"=>issue_title, "description"=>issue_description,"project"=>{"key"=>params['project_id']},"issuetype"=>{"id"=>"3"},"priority"=>{"name"=>params['issue_priority']}}}
        
        issue_build = client.Issue.build
        issue_build.save(issue)
        
        problem.update_attributes(
          :issue_link => jira_url(issue_build.key),
          :issue_type => params['issue_type']
        )

      rescue JIRA::HTTPError
        raise ErrbitJiraPlugin::IssueError, "Could not create an issue with Jira.  Please check your credentials."
      end
    end

    def jira_url(project_id)
      "#{params['base_url']}#{ctx_path}browse/#{project_id}"
    end

    def ctx_path
      (params['context_path'] == '') ? '/' : params['context_path']
    end

    def url
      params['base_url']
    end
  end
end
