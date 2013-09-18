#
# Author:: Benjamin Black (<bb@opscode.com>)
# Author:: Claire McQuin (<claire@opscode.com>)
# Copyright:: Copyright (c) 2009, 2013 Opscode, Inc.
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

module Ohai
  module Common
    module Virtualization

      def host?(virtualization)
        !virtualization.nil? && virtualization[:role].eql?("host")
      end

      def open_virtconn(system)
        begin
          require 'libvirt'
          require 'hpricot'
        rescue LoadError => e
          Ohai::Log.debug("Cannot load gem: #{e}.")
        end

        emu = (system.eql?('kvm') ? 'qemu' : system)
        virtconn = Libvirt::open_read_only("#{emu}:///system")
      end

      def close_virtconn(v)
        v.close
      end

      def libvirt_version(system)
        emu = (system.eql?('kvm') ? 'qemu' : system)
        libvirt_version = Libvirt::version(emu)[0].to_s
      end

      def nodeinfo(virtconn)
        nodeinfo Mash.new
        ni = virtconn.node_get_info
        ['cores', 'cpus', 'memory', 'mhz', 'model', 'nodes', 'sockets', 'threads'].each { |a| nodeinfo[a] = ni.send(a) }
        nodeinfo
      end

      def uri(virtconn)
        virtconn.uri
      end

      def capabilities(virtconn)
        capabilities Mash.new
        capabilities[:xml_desc] = (virtconn.capabilities.split("\n").collect {|line| line.strip}).join
        #xdoc = Hpricot capabilities[:xml_desc]
        capabilities
      end

      def domains(virtconn)
        domains = Mash.new
        virtconn.list_domains.each do |d|
          dv = virtconn.lookup_domain_by_id d
          domains[dv.name] = Mash.new
          domains[dv.name][:id] = d
          domains[dv.name][:xml_desc] = (dv.xml_desc.split("\n").collect {|line| line.strip}).join
          ['os_type','uuid'].each {|a| domains[dv.name][a] = dv.send(a)}
          ['cpu_time','max_mem','memory','nr_virt_cpu','state'].each {|a| domains[dv.name][a] = dv.info.send(a)}
          #xdoc = Hpricot domains[dv.name][:xml_desc]
        end
        domains
      end

      def networks(virtconn)
        networks = Mash.new
        virtconn.list_networks.each do |n|
          nv = virtconn.lookup_network_by_name n
          networks[n] = Mash.new
          networks[n][:xml_desc] = (nv.xml_desc.split("\n").collect {|line| line.strip}).join
          ['bridge_name','uuid'].each {|a| networks[n][a] = nv.send(a)}
          #xdoc = Hpricot networks[n][:xml_desc]
        end
        networks
      end

      def storage(virtconn)
        storage = Mash.new
        virtconn.list_storage_pools.each do |pool|
          sp = virtconn.lookup_storage_pool_by_name pool
          storage[pool] = Mash.new
          storage[pool][:xml_desc] = (sp.xml_desc.split("\n").collect {|line| line.strip}).join
          ['autostart','uuid'].each {|a| storage[pool][a] = sp.send(a)}
          ['allocation','available','capacity','state'].each {|a| storage[pool][a] = sp.info.send(a)}
          #xdoc = Hpricot storage]pool][:xml_desc]

          storage[pool][:volumes] = Mash.new
          sp.list_volumes.each do |v|
            storage[pool][:volumes][v] = Mash.new
            sv = sp.lookup_volume_by_name v
            ['key','name','path'].each {|a| storage[pool][:volumes][v][a] = sv.send(a)}
            ['allocation','capacity','type'].each {|a| storage[pool][:volumes][v][a] = sv.info.send(a)}
          end
        end
        storage
      end

    end
  end
end
