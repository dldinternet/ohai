#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2008 Opscode, Inc.
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


require File.expand_path(File.dirname(__FILE__) + '/../../../spec_helper.rb')

describe Ohai::System, "FreeBSD hostname plugin" do
  before(:each) do
    @plugin = get_plugin("freebsd/hostname")
    @plugin[:os] = "freebsd"
    @plugin.stub(:shell_out).with("hostname -s").and_return(mock_shell_out(0, "katie", ""))
    @plugin.stub(:shell_out).with("hostname -f").and_return(mock_shell_out(0, "katie.bethell", ""))
  end
  
  it_should_check_from("freebsd::hostname", "hostname", "hostname -s", "katie")
  
  it_should_check_from("freebsd::hostname", "fqdn", "hostname -f", "katie.bethell")
end
