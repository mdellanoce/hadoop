#
# Cookbook Name:: hadoop
# Recipe:: hive_mysql
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

include_recipe "hadoop::hive"

package "libmysql-java"

link "/usr/lib/hive/lib/mysql-connector-java.jar" do
  to "/usr/share/java/mysql-connector-java.jar"
end

host = node[:hadoop][:hive_metastore_host]
user = node[:hadoop][:hive_mysql_user]
password = node[:hadoop][:hive_mysql_password]
mysql_password = node[:mysql][:server_root_password]
database = node[:hadoop][:hive_mysql_database]
create_database = "CREATE DATABASE IF NOT EXISTS #{database};"
create_metastore_schema = "/usr/lib/hive/scripts/metastore/upgrade/mysql/hive-schema-0.10.0.mysql.sql"
create_hive_user = [
  "CREATE USER '#{user}'@'#{host}' IDENTIFIED BY '#{password}';",
  "REVOKE ALL PRIVILEGES, GRANT OPTION FROM '#{user}'@'#{host}';",
  "GRANT SELECT,INSERT,UPDATE,DELETE,LOCK TABLES,EXECUTE ON #{database}.* TO '#{user}'@'#{host}';",
  "FLUSH PRIVILEGES;"
].join('')
mysql_cmd = "mysql -u root --password=#{mysql_password}"
hive_warehouse_dir = "/user/hive/warehouse"

execute "create metastore database" do
  command "#{mysql_cmd} --execute='#{create_database}'"
end

execute "create metastore schema" do
  command "#{mysql_cmd} --database=#{database} < #{create_metastore_schema}"
end

execute "create hive mysql user" do
  command "#{mysql_cmd} --execute=\"#{create_hive_user}\""
  not_if "#{mysql_cmd} --execute=\"SELECT 1 FROM mysql.user WHERE user='#{user}'\" | grep 1"
end

execute "create hive warehouse directory" do
  command "hadoop fs -mkdir -p #{hive_warehouse_dir}"
  user "hdfs"
end

execute "set hive warehouse directory permissions" do
  command "hadoop fs -chmod 1777 #{hive_warehouse_dir}"
  user "hdfs"
end

template "/etc/hive/conf/hive-site.xml" do
  source "hive-site.xml.erb"
  mode 0644
end
