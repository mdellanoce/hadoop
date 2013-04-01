#
# Cookbook Name:: hadoop
# Recipe:: conf_pseudo 
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
# Instructions:
# https://ccp.cloudera.com/display/CDH4DOC/Deploying+MapReduce+v1+%28MRv1%29+on+a+Cluster

include_recipe "hadoop"

package "hadoop-0.20-conf-pseudo"

def run_as_hdfs(command, &block)
  execute command do
    action :run
    user "hdfs"
    instance_eval(&block) if block_given?
  end
end

run_as_hdfs "hdfs namenode -format -nonInteractive" do
  returns [0,1]
end

%w{hdfs-namenode hdfs-secondarynamenode hdfs-datanode}.each do |d|
  service "hadoop-#{d}" do
    action [ :start, :enable ]
  end
end

mapred_cache_dir = "/var/lib/hadoop-hdfs/cache/mapred"
mapred_system_dir = "/tmp/mapred/system"
commands = [
  "hadoop fs -mkdir -p /tmp",
  "hadoop fs -mkdir -p #{mapred_cache_dir}/staging",
  "hadoop fs -chmod 1777 #{mapred_cache_dir}/staging",
  "hadoop fs -chown -R mapred #{mapred_cache_dir}",
  "hadoop fs -mkdir -p #{mapred_system_dir}",
  "hadoop fs -chown mapred:hadoop #{mapred_system_dir}"
]

commands.each do |command|
  run_as_hdfs command
end

%w{jobtracker tasktracker}.each do |d|
  service "hadoop-0.20-mapreduce-#{d}" do
    action [ :start, :enable ]
  end
end

node[:hadoop][:users].each do |user|
  home_dir = "/user/#{user}"
  commands = [
    "hadoop fs -mkdir -p #{home_dir}",
    "hadoop fs -chown #{user} #{home_dir}"
  ]
  commands.each do |command|
    run_as_hdfs command
  end
end
