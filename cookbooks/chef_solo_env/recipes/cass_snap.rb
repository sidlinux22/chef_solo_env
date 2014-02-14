

template "/tmp/cassandra-testdata-snapshot.tgz" do
  source "cassandra-testdata-snapshot.tgz"
  owner 'root' and mode 0644
end

execute "unpack cassandra test data snapshot" do
  cwd "/opt/cassandra-backup"
  command "tar xfz /tmp/cassandra-testdata-snapshot.tgz"
  not_if(File.exists?( "/opt/cassandra-backup/.snapshot_imported" ).to_s)
end

execute "import cassandra test data snapshot" do
  user "cassandra"
  group "cassandra"
  cwd "/opt/cassandra-backup"
  command %Q{ ./bin/import.sh && touch /opt/cassandra-backup/.snapshot_imported && cd /opt/cassandra-backup/snapshots && rm -f /opt/cassandra-backup/log/snapshot-1382577525.log && rm -Rf ./138257752601./7/ }
  not_if(File.exists?( "/opt/cassandra-backup/.snapshot_imported" ).to_s)
  notifies :start, resources(:service => "cassandra")
end
