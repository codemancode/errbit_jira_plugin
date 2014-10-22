require 'jira'

module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'jira'

    NOTE = 'Please configure Jira by entering your <strong>username</strong>, <strong>password</strong> and <strong>Jira install url</strong>.'

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
            :optional => true,
            :label => 'HTTP Basic Auth User',
            :placeholder => 'johndoe'
        }],
        [:password, {
            :optional => true,
            :label => 'HTTP Basic Auth Password',
            :placeholder => 'p@assW0rd'
        }],
        [:project_id, {
            :label => 'Project Key',
            :placeholder => 'The project Key where the issue will be created'
        }],
        [:account, {
            :optional => true,
            :label => 'Assign to this user. If empty, Jira takes the project default.',
            :placeholder => "username"
        }],
        [:issue_component, {
            :optional => true,
            :label => 'Issue category',
            :placeholder => 'Website - Other'
        }],
        [:issue_type, {
            :label => 'Issue type',
            :placeholder => 'Bug'
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
        logger = Logger.new(STDOUT)
        issue_title =  "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}".delete!("\n")
        issue_description = self.class.body_template.result(binding).unpack('C*').pack('U*')
        issue = {"fields"=>{"summary"=>issue_title, "description"=>issue_description,"project"=>{"key"=>params['project_id']},"issuetype"=>{"name"=>params['issue_type']},"priority"=>{"name"=>params['issue_priority']}}}
        #issue[:fields][:assignee] = {:name => params['account']} if params['account']
        #issue[:fields][:components] = {:name => params['issue_component']} if params['issue_component']
        issue_build = client.Issue.build
        issue_build.save(issue)
        logger.info "----- #{issue_build.inspect}"
        problem.update_attributes(
          :issue_link => jira_url('TEST-13'),
          :issue_type => params['issue_type']
        )

      rescue JIRA::HTTPError
        raise ErrbitJiraPlugin::IssueError, "Could not create an issue with Jira.  Please check your credentials."
      end
    end

    def jira_url(project_id)
      ctx_path = (params['context_path'] == '') ? '/' : params['context_path']
      "#{params['base_url']}#{ctx_path}browse/#{project_id}"
    end

    def url
      params['base_url']
    end
  end
end
