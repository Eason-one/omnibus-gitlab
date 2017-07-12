#
# Copyright:: Copyright (c) 2017 GitLab Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

module Services # rubocop:disable Style/MultilineIfModifier (disabled so we can use `unless defined?(Services)` at the end of the class definition)
  class Config
    SYSTEM_GROUP = 'system'.freeze
    DEFAULT_GROUP = 'default'.freeze

    def self.list
      @services.dup
    end

    def self.service(name, **config)
      @services ||= {}

      # A service config object always needs a group array
      @services[name] = { groups: [] }.merge(config)
    end
  end

  class << self
    # Disables the group of services that were passed as arguments, or all
    # services if no services are provided
    #
    # Excludes the group, or array of groups, provided in the `except` argument
    # ex: Services.disable_group('redis')
    #     Services.disable_group('prometheus' except: ['redis', 'postgres'])
    #     Services.disable_group(except: 'redis')
    def disable_group(*groups, except: nil, include_system: false)
      exceptions = [except].flatten
      exceptions << Config::SYSTEM_GROUP unless include_system
      set_enabled_group(false, *groups, except: exceptions)
    end

    # Enables the group of services that were passed as arguments, or all
    # services if no services are provided
    #
    # Excludes the group, or array of groups, provided in the `except` argument
    # ex: Services.enable_group('redis')
    #     Services.enable_group('prometheus' except: ['redis', 'postgres'])
    #     Services.enable_group(except: 'redis')
    def enable_group(*groups, except: nil)
      set_enabled_group(true, *groups, except: except)
    end

    # Disables the services that were passed as arguments, or all services if
    # no services are provided
    #
    # Excludes the service, or array of services, provided in the `except` argument
    # ex: Services.disable('mailroom')
    #     Services.disable(except: ['redis', 'sentinel'])
    def disable(*services, except: nil, include_system: false)
      # Automatically excludes system services unless `include_system: true` is passed
      exceptions = [except].flatten
      exceptions.concat(system_services.keys) unless include_system

      set_enabled(false, *services, except: exceptions)
    end

    # Enables the services that were passed as arguments, or all services if
    # no services are provided
    #
    # Excludes the service, or array of services, provided in the `except` argument
    # ex: Services.enable('mailroom')
    #     Services.enable(except: ['prometheus'])
    def enable(*services, except: nil)
      set_enabled(true, *services, except: except)
    end

    def system_services
      find_by_group(Config::SYSTEM_GROUP)
    end

    def find_by_group(group)
      service_list.select { |name, service| service[:groups].include?(group) }
    end

    def service_list
      # Merge together and cache all the service lists (from the different cookbooks)
      @service_list ||= [*cookbook_services.dup.values].inject(&:merge)
    end

    def add_services(cookbook, services)
      # Add services from cookbooks
      cookbook_services[cookbook] = services
    end

    def reset_list
      @cookbook_services = nil
      @service_list = nil
    end

    private

    def cookbook_services(value = nil)
      @cookbook_services = value if value
      @cookbook_services ||= {}
    end

    def set_enabled(enable, *services, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, _|
        # Set the service enable config if:
        #  The current service is not in the list of exceptions
        #  AND
        #  The current service was requested to be set, or no specific service was
        #  requested, so we are setting them all
        if !exceptions.include?(name) && (services.empty? || services.include?(name))
          Gitlab[name]['enable'] = enable
        end
      end
    end

    def set_enabled_group(enable, *groups, except: nil)
      exceptions = [except].flatten
      service_list.each do |name, service|
        # Find the matching groups among our passed arguments and our current service's groups
        matching_exceptions = exceptions & service[:groups]
        matching_groups = groups & service[:groups]

        # Set the service enable config if:
        #  The current service has no matching exceptions
        #  AND
        #  The current service has matching groups that were requested to be set,
        #  or no specific group was requested, so we are setting them all
        if matching_exceptions.empty? && (groups.empty? || !matching_groups.empty?)
          Gitlab[name]['enable'] = enable
        end
      end
    end
  end
end unless defined?(Services) # Prevent reloading during converge, so we can test
