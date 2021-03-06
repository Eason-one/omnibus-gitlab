require_relative '../trigger'
require_relative '../info'
require_relative '../../version'

require 'cgi'

module Build
  class HA
    class ValidateNightly
      extend Trigger

      PROJECT_PATH = 'gitlab-org/distribution/gitlab-provisioner'.freeze

      def self.get_project_path
        PROJECT_PATH
      end

      def self.package_url
        base_url = 'https://omnibus-builds.s3.amazonaws.com/ubuntu-xenial/gitlab-ee_'
        build_version = CGI.escape(Build::Info.semver_version)
        build_iteration = Gitlab::BuildIteration.new.build_iteration
        "#{base_url}#{build_version}-#{build_iteration}_amd64.deb"
      end

      def self.get_params(image: nil)
        {
          'ref' => 'master',
          'token' => ENV['HA_VALIDATE_TOKEN'],
          'variables[QA_IMAGE]' => 'gitlab/gitlab-ee-qa:nightly',
          'variables[PACKAGE_URL]' => package_url
        }
      end

      def self.get_access_token
        ENV['HA_VALIDATE_TOKEN']
      end
    end
  end
end
