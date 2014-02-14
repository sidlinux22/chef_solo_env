##### request-log-analyzer

execute "install Request Log Analyzer" do
          user "root"
          command "gem install request-log-analyzer"
          only_if(!File.exists?( "/usr/bin/ruby" ).to_s)
          not_if(File.exists?( "/local/bin/request-log-analyzer" ).to_s)
end

cron "request-log-analzer_report_cronjob" do
  action :create
  minute "0"
  hour "12"
  user "root"
  mailto "root@localhost"
  command "/usr/local/bin/request-log-analyzer --mail root@localhost -b --format nginx --silent /var/log/nginx/*.log"
end


#####Cassandra

bash "add_cassandra_topath" do
  user "root"
  cwd "/"
  code <<-EOH
    grep -q "/usr/local/cassandra/bin" /etc/environment || echo PATH="$PATH:/usr/local/cassandra/bin" > /etc/environment
  EOH
end
#cassandra backup tar to /tmp
template "/tmp/cassandra-backup.tgz" do
  source "cassandra-backup.tgz"
  owner 'root' and mode 0644
end
#Unpack Backup
bash "unpack_cassandra_backup_to_opt" do
  user "root"
  cwd "/opt"
  code <<-EOH
    tar xfvz /tmp/cassandra-backup.tgz
  EOH
end
#Backup Cron
cron "cassandra_snapshot_cronjob" do
  action :create
  minute "0"
  hour "12"
  user "cassandra"
  mailto "root@localhost"
  home "/opt/cassandra-backup"
  command "./bin/export.sh"
end

##Deploy using TOMCAT

template "/tmp/sample.war" do
  source "sample.war"
  owner 'root' and mode 0644
end

execute "deploy tomcat sample app" do
          user "root"
          cwd  "/var/lib/tomcat6/webapps/ROOT"
          command "rm -Rf * && jar -xvf /tmp/sample.war"
          only_if(!File.exists?( "/tmp/sample.war" ).to_s)
          not_if(File.exists?( "/var/lib/tomcat6/webapps/ROOT/hello.jsp" ).to_s)
end

server_ssl_req = "/C=US/ST=Several/L=Locality/O=Example/OU=Operations/CN=#{node[:fqdn]}/emailAddress=root@#{node[:fqdn]}"
execute "Create SSL Certs" do
  command "openssl req -subj \"#{server_ssl_req}\" -new -nodes -x509 -out /etc/nginx/cert.pem -keyout /etc/nginx/cert.key"
  only_if(!File.exists?( "/etc/nginx/cert.pem" ).to_s)
  not_if(File.exists?( "/etc/nginx/cert.key" ).to_s)
end

template "#{node[:nginx][:dir]}/sites-available/tomcat6.conf" do
  source "tomcat_conf.erb"
  owner 'root' and mode 0644

  notifies :restart, resources(:service => "nginx")
end

bash "symlink" do
  user "root"
  cwd "#{node[:nginx][:dir]}/sites-enabled"
  code <<-EOH
    ln  -s -f ../sites-available/tomcat6.conf .
  EOH
  notifies :restart, resources(:service => "nginx")
end

template "#{node[:monit][:includes_dir]}/nginx.monitrc" do
  source "nginx.monitrc.erb"
  owner 'root' and mode 0644

  notifies :restart, resources(:service => "monit")
end

template "#{node[:monit][:includes_dir]}/tomcat6.monitrc" do
  source "tomcat_monitrc.erb"
  owner 'root' and mode 0644

  notifies :restart, resources(:service => "monit")
end


