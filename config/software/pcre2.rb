#
# Copyright 2018 GitLab Inc.
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

name 'pcre2'
default_version '10.31'

license 'BSD-2-Clause'
license_file 'LICENCE'

dependency 'libedit'
dependency 'ncurses'
dependency 'config_guess'

version '10.31' do
  source md5: '10e1a95a0f0d80759f1b3d70e92c2cda'
end

source url: "http://downloads.sourceforge.net/project/pcre/pcre2/#{version}/pcre2-#{version}.tar.gz"

relative_path "pcre2-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  update_config_guess

  command './configure' \
          " --prefix=#{install_dir}/embedded" \
          ' --disable-cpp' \
          ' --enable-utf' \
          ' --enable-unicode-properties' \
          ' --enable-jit' \
          ' --enable-pcretest-libedit', env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end

project.exclude "embedded/bin/pcre2-config"
