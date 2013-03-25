#
# Cookbook Name:: hadoop
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

platform = "debian" if platform?("debian")
platform = "ubuntu" if platform?("ubuntu")
codename = node[:lsb][:codename]

uri = "http://archive.cloudera.com/cdh4/#{platform}/#{codename}/amd64/cdh"
file "/etc/apt/sources.list.d/cloudera.list" do
  owner "root"
  group "root"
  mode 00644
  content "deb [arch=amd64] #{uri} #{codename}-cdh4 contrib"
  action :create
end

cached_keyfile = "#{Chef::Config[:file_cache_path]}/archive.key"
remote_file cached_keyfile do
  source "http://archive.cloudera.com/cdh4/#{platform}/#{codename}/amd64/cdh/archive.key"
  mode 00644
  action :create
end

execute "apt-key add #{cached_keyfile}" do
  action :run
end

execute "apt-get update" do
  action :run
end

include_recipe "java"

package "hadoop"

