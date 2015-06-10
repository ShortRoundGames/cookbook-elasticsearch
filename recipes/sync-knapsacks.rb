# Create script that syncs Knapsack archives to S3
template "/data/sync-knapsacks.sh" do
  source "sync-knapsacks.sh.erb"
  mode "0550"
  owner "root"
  group "root"
end

# Cron it so that it runs every day, 1 hour after the snapshot job
cron "sync-knapsacks" do
	minute "30"
	hour "6"
	command "/data/sync-knapsacks.sh"
end
