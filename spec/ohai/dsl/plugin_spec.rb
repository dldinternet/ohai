#
# Author:: Adam Jacob (<adam@opscode.com>)
# Author:: Daniel DeLeo (<dan@opscode.com>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2008, 2012, 2013 Opscode, Inc.
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
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
# implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require File.expand_path("../../../spec_helper", __FILE__)

shared_examples "Ohai::DSL::Plugin" do
  it "should save the plugin source file" do
    plugin.file.should eql(source)
  end

  it "should set has_run? to false" do
    plugin.has_run?.should be_false
  end

  it "should set has_run? to true after running the plugin" do
    plugin.stub(:run_plugin).and_return(true)
    plugin.run
    plugin.has_run?.should be_true
  end

  context "when accessing data via method_missing" do
    it "should take a missing method and store the method name as a key, with its arguments as values" do
      plugin.guns_n_roses("chinese democracy")
      plugin.data["guns_n_roses"].should eql("chinese democracy")
    end

    it "should return the current value of the method name" do
      plugin.guns_n_roses("chinese democracy").should eql("chinese democracy")
    end

    it "should allow you to get the value of a key by calling method_missing with no arguments" do
      plugin.guns_n_roses("chinese democracy")
      plugin.guns_n_roses.should eql("chinese democracy")
    end
  end

  context "when checking attribute existence" do
    before(:each) do
      plugin.metallica("death magnetic")
    end

    it "should return true if an attribute exists with the given name" do
      plugin.attribute?("metallica").should eql(true)
    end

    it "should return false if an attribute does not exist with the given name" do
      plugin.attribute?("alice in chains").should eql(false)
    end
  end

  context "when setting attributes" do
    it "should let you set an attribute" do
      plugin.set_attribute(:tea, "is soothing")
      plugin.data["tea"].should eql("is soothing")
    end
  end

  context "when getting attributes" do
    before(:each) do
      plugin.set_attribute(:tea, "is soothing")
    end

    it "should let you get an attribute" do
      plugin.get_attribute("tea").should eql("is soothing")
    end
  end
end

describe Ohai::DSL::Plugin::VersionVI do
  describe "#version" do
    it "should return :version6" do
      Ohai::DSL::Plugin::VersionVI.new(Ohai::System.new, "").version.should eql(:version6)
    end
  end

  describe "#provides" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should add a provided attribute to Ohai" do
      klass = Ohai.v6plugin { collect_contents("provides(\"attr\")") }
      plugin = klass.new(@ohai, "")
      plugin.run_plugin

      @ohai.attributes.should have_key(:attr)
    end

    it "should save the provider for an attribute" do
      klass = Ohai.v6plugin { collect_contents("provides(\"attr\")") }
      plugin = klass.new(@ohai, "")
      plugin.run_plugin

      @ohai.attributes[:attr][:_providers].should include(plugin)
    end

    it "should save each provider for an attribute" do
      klass = Ohai.v6plugin { collect_contents("provides(\"attr\")") }
      plugin1 = klass.new(@ohai, "")
      plugin2 = klass.new(@ohai, "")

      plugin1.run_plugin
      plugin2.run_plugin

      [plugin1, plugin2].each do |plugin|
        @ohai.attributes[:attr][:_providers].should include(plugin)
      end
    end

    it "should save multi-level attributes (i.e., attr/subattr)" do
      klass = Ohai.v6plugin { collect_contents("provides(\"attr/subattr\")") }
      plugin = klass.new(@ohai, "")
      plugin.run_plugin

      @ohai.attributes.should have_key(:attr)
      @ohai.attributes[:attr].should have_key(:subattr)
    end

    it "should save the provider for a multi-level attribute" do
      klass = Ohai.v6plugin { collect_contents("provides(\"attr/subattr\")") }
      plugin = klass.new(@ohai, "")
      plugin.run_plugin

      @ohai.attributes[:attr][:subattr][:_providers].should include(plugin)
    end
  end

  describe "#require_plugin" do
    before(:each) do
      @ohai = Ohai::System.new
    end

    it "should require the plugin through Ohai::System" do
      klass = Ohai.v6plugin { collect_contents("require_plugin(\'other\')") }
      plugin = klass.new(@ohai, "")

      @ohai.should_receive(:require_plugin).with(['other'])
      plugin.run_plugin
    end

    it "should require each plugin through Ohai::System" do
      klass = Ohai.v6plugin { collect_contents("require_plugin(\'some\', \'other\', \'plugin\')") }
      plugin = klass.new(@ohai, "")

      @ohai.should_receive(:require_plugin).with(['some', 'other', 'plugin'])
      plugin.run_plugin
    end
  end

  describe "#self.collect_contents" do
    it "should define run_plugin" do
      klass = Ohai.v6plugin { collect_contents("") }
      klass.method_defined?(:run_plugin)
    end
  end

  it_behaves_like "Ohai::DSL::Plugin" do
    let(:ohai) { Ohai::System.new }
    let(:source) { "/tmp/plugins/test.rb" }
    let(:plugin) { Ohai::DSL::Plugin::VersionVI.new(ohai, source) }
  end
end

describe Ohai::DSL::Plugin::VersionVII do
  describe "#version" do
    it "should return :version7" do
      Ohai::DSL::Plugin::VersionVII.new(Ohai::System.new, "").version.should eql(:version7)
    end
  end

  describe "#self.provides" do
    before(:each) do
      @name = :Test
    end

    after(:each) do
      Ohai::NamedPlugin.send(:remove_const, @name)
    end

    it "should collect a single attribute" do
      klass = Ohai.plugin(@name) { provides("attr") }
      klass.provides_attrs.should include("attr")
    end

    it "should collect a list of attributes" do
      klass = Ohai.plugin(@name) { provides("attr1", "attr2") }
      %w{ attr1 attr2 }.each do |attr|
        klass.provides_attrs.should include(attr)
      end
    end

    it "should collect from multiple provides statements" do
      klass = Ohai.plugin(@name) { provides("attr1"); provides("attr2", "attr3") }
      %w{ attr1 attr2 attr3 }.each do |attr|
        klass.provides_attrs.should include(attr)
      end
    end
  end

  describe "#self.depends" do
    before(:each) do
      @name = :Test
    end

    after(:each) do
      Ohai::NamedPlugin.send(:remove_const, @name)
    end

    it "should collect a single dependency" do
      klass = Ohai.plugin(@name) { depends("attr") }
      klass.depends_attrs.should include("attr")
    end

    it "should collect a list of dependencies" do
      klass = Ohai.plugin(@name) { depends("attr1", "attr2") }
      %w{ attr1 attr2 }.each do |attr|
        klass.depends_attrs.should include(attr)
      end
    end

    it "should collect from multiple depends statments" do
      klass = Ohai.plugin(@name) { depends("attr1"); depends("attr2", "attr3") }
      %w{ attr1 attr2 attr3 }.each do |attr|
        klass.depends_attrs.should include(attr)
      end
    end
  end

  describe "#self.collect_data" do
    before(:each) do
      @name = :Test
    end

    after(:each) do
      Ohai::NamedPlugin.send(:remove_const, @name)
    end

    it "should set platform as :default if no platform is specified" do
      klass = Ohai.plugin(@name) { collect_data { } }
      klass.collector.should have_key(:default)
    end

    it "should set :platform, when provided" do
      klass = Ohai.plugin(@name) { collect_data(:ubuntu) { } }
      klass.collector.should have_key(:ubuntu)
    end

    it "should collect from multiple collect data blocks (unique platforms)" do
      klass = Ohai.plugin(@name) { collect_data(:darwin) { }; collect_data(:default) { }; collect_data(:ubuntu) { } }
      [:darwin, :default, :ubuntu].each do |platform|
        klass.collector.should have_key(platform)
      end
    end
  end

  describe "#

  it_behaves_like "Ohai::DSL::Plugin" do
    let(:ohai) { Ohai::System.new }
    let(:source) { "/tmp/plugins/test.rb" }
    let(:plugin) { Ohai::DSL::Plugin::VersionVII.new(ohai, source) }
  end
end
