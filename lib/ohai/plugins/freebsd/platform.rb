#
# Author:: Bryan McLellan (<btm@loftninjas.org>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2009 Bryan McLellan
# Copyright:: Copyright (c) 2013 Opscode, Inc.
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

require 'ohai/common/platform'

Ohai.plugin(:Platform) do
  include Ohai::Common::Platform
  provides "platform", "platform_version"

  def from_cmd(cmd)
    so = shell_out(cmd)
    so.stdout.split($/)[0]
  end

  collect_data(:freebsd, :netbsd, :openbsd) do
    platform from_cmd("uname -s").downcase
    platform_version from_cmd("uname -r")

    platform get_platform unless attribute?(platform)
    platform_version get_platform_version unless attribute?(platform_version)
    platform_family get_platform_family unless attribute?(platform_family)
  end
end
