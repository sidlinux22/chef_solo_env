##
## Nginx
##

# create Self signed ssl cert for nginix
server_ssl_req = "/C=US/ST=Several/L=Locality/O=Example/OU=Operations/CN=#{node[:fqdn]}/emailAddress=root@#{node[:fqdn]}"
execute "Create SSL Certs" do
  command "openssl req -subj \"#{server_ssl_req}\" -new -nodes -x509 -out /etc/nginx/cert.pem -keyout /etc/nginx/cert.key"
  only_if(!File.exists?( "/etc/nginx/cert.pem" ).to_s)
  not_if(File.exists?( "/etc/nginx/cert.key" ).to_s)
end

# Create Nginix Tomcat site configuration
template "#{node[:nginx][:dir]}/sites-available/tomcat7.conf" do
  source "tomcat7.conf.erb"
  owner 'root' and mode 0644

  notifies :restart, resources(:service => "nginx")
end

# Symlinking tomcat config snippet "enabled"
bash "symlink" do
  user "root"
  cwd "#{node[:nginx][:dir]}/sites-enabled"
  code <<-EOH
    ln -s -f ../sites-available/tomcat7.conf .
  EOH
  notifies :restart, resources(:service => "nginx")
end

## Tomcat 
##

# deploy sample appilication in /tmp
template "/tmp/sample.war" do
  source "sample.war"
  owner 'root' and mode 0644
end

# deploy tomcat sample app 
execute "deploy tomcat sample app" do
          user "root"
          cwd  "/var/lib/tomcat7/webapps/ROOT"
          command "rm -Rf * && jar -xvf /tmp/sample.war"
          only_if(!File.exists?( "/tmp/sample.war" ).to_s)
          not_if(File.exists?( "/var/lib/tomcat7/webapps/ROOT/hello.jsp" ).to_s)
end

## Cassandra
##


# add cassandra bin to System PATH
bash "add_cassandra_topath" do
  user "root"
  cwd "/"
  code <<-EOH
    grep -q "/usr/local/cassandra/bin" /etc/environment || echo PATH="$PATH:/usr/local/cassandra/bin" > /etc/environment
  EOH
end

# copy cassandra backup tar to /tmp
template "/tmp/cassandra-backup.tgz" do
  source "cassandra-backup.tgz"
  owner 'root' and mode 0644
end

# unpack the cassandra-backup tar in opt
bash "unpack_cassandra_backup_to_opt" do
  user "root"
  cwd "/opt"
  code <<-EOH
    tar xfvz /tmp/cassandra-backup.tgz
  EOH
end

# install cassandra backup snapshot cronjob
# daily 10:00 UTC
cron "cassandra_snapshot_cronjob" do
  action :create
  minute "0"
  hour "14"
  user "cassandra"
  mailto "root@localhost"
  home "/opt/cassandra-backup"
  command "./bin/export.sh"
end

##
## Base Packages - i really need vim and mailx for reading mail :)
##

%w{mailutils vim ruby1.9.1-full}.each do |pkg|
  apt_package pkg do
	  action :install
  end
end

##
## request-log-analyzer
##
execute "install Request Log Analyzer" do
          user "root"
          command "gem install request-log-analyzer"
          only_if(!File.exists?( "/usr/bin/ruby" ).to_s)
          not_if(File.exists?( "/local/bin/request-log-analyzer" ).to_s)
end

# daily email report cronjob at 14:00 UTC
cron "request-log-analzer_report_cronjob" do
  action :create
  minute "0"
  hour "14"
  user "root"
  mailto "root@localhost"
  command "/usr/local/bin/request-log-analyzer --mail root@localhost -b --format nginx --silent /var/log/nginx/*.log"
end
