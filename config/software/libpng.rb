#
# Copyright:: Copyright (c) 2018 GitLab Inc.
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

name 'libpng'
default_version '1.6.34'

license 'Libpng'
license_file 'LICENSE'

dependency 'zlib'

source url: "https://download.sourceforge.net/libpng/libpng-#{version}.tar.gz",
       sha256: '574623a4901a9969080ab4a2df9437026c8a87150dfd5c235e28c94b212964a7'

relative_path "libpng-#{version}"

build do
  env = with_standard_compiler_flags(with_embedded_path)

  configure_command = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    "--with-zlib=#{install_dir}/embedded"
  ]

  command configure_command.join(' '), env: env

  make "-j #{workers}", env: env
  make 'install', env: env
end
