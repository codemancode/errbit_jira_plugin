require 'jira'

module ErrbitJiraPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'jira'

    NOTE = 'Please configure Jira by entering the information below.'

    FIELDS = {
      :base_url => {
          :label => 'Jira URL without trailing slash',
          :placeholder => 'https://jira.example.org'
      },
      :context_path => {
          :optional => true,
          :label => 'Context Path (Just "/" if empty otherwise with leading slash)',
          :placeholder => "/jira"
      },
      :username => {
          :label => 'Username',
          :placeholder => 'johndoe'
      },
      :password => {
          :label => 'Password',
          :placeholder => 'p@assW0rd'
      },
      :project_id => {
          :label => 'Project Key',
          :placeholder => 'The project Key where the issue will be created'
      },
      :issue_priority => {
          :label => 'Priority',
          :placeholder => 'Normal'
      }
    }

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    def self.fields
      FIELDS
    end

    def self.icons
      @icons ||= {
        create: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_create.png')
        ],
        goto: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_goto.png'),
        ],
        inactive: [
          'image/png', ErrbitJiraPlugin.read_static_file('jira_inactive.png'),
        ]
      }
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
      if self.class.fields.detect {|f| options[f[0]].blank? }
        errors << [:base, 'You must specify all non optional values!']
      end
      errors
    end

    def comments_allowed?
      false
    end

    def client
      jira_options = {
        :username => params['username'],
        :password => params['password'],
        :site => params['base_url'],
        :auth_type => :basic,
        :context_path => (params['context_path'] == '/') ? params['context_path'] = '' : params['context_path']
      }
      JIRA::Client.new(options)
    end

    def create_issue(title, body, user: {})
      begin
        issue_fields =  {
                          "fields" => {
                            "summary" => title,
                            "description" => body,
                            "project"=> {"key"=>params['project_id']},
                            "issuetype"=>{"id"=>"3"},
                            "priority"=>{"name"=>params['issue_priority']}
                          }
                        }
        jira_issue = client.Issue.build

        issue_build.save(issue_fields)

        jira_url(issue_build.key)
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

    private

    def build_issue_fields(title, body)

    end

    def params
      options
    end
  end
end
