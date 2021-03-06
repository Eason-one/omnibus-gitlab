#
# Copyright 2012-2016 Chef Software, Inc.
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

name 'bundler'
# Pin the bundler version to avoid breaking changes in later versions
default_version '1.16.2'

license 'MIT'
license_file 'https://raw.githubusercontent.com/bundler/bundler/master/LICENSE.md'

dependency 'rubygems'

build do
  env = with_standard_compiler_flags(with_embedded_path)

  v_opts = "--version '#{version}'" unless version.nil?

  gem [
    'install bundler',
    v_opts,
    '--no-ri --no-rdoc --force'
  ].compact.join(' '), env: env

  # Needed until a release includes https://github.com/bundler/bundler/pull/6550
  if version.satisfies?('>= 1.14.0')
    patch source: 'bundler-homedir-workaround.patch',
          target: "#{install_dir}/embedded/lib/ruby/gems/2.4.0/gems/bundler-#{version}/lib/bundler.rb",
          plevel: 1,
          env: env
  end
end
