def run_ssh_with(server, cmd)
  user = fetch(:user)
  path = fetch(:deploy_to)

  uri = [
      user,
      user && "@",
      server.hostname,
      server.port && ":",
      server.port
  ].compact.join

  exec("ssh -t #{uri} 'cd #{path}/current && #{cmd}'")
end

desc "Login into a server based on the deployment stage"
task :login do
  on roles(:app) do |server|
    run_ssh_with(server, "exec $SHELL -l")
  end
end

desc "Open Rails console on a server based on the deployment stage"
task :console do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    console_cmd = "/home/rails/.rbenv/shims/bundle exec rails console -e #{env}"
    run_ssh_with(server, console_cmd)
  end
end

desc "Monitor log"
task :log do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    run_ssh_with(server, "tail -f log/#{env}.log")
  end
end

desc "Start puma sever based on the deployment stage"
task :restart do
  on roles(:app) do |server|
    env = fetch(:rails_env)

    execute :kill, "-9 $(lsof -t -i:3000 -sTCP:LISTEN) || true"
    console_cmd = "/home/rails/.rbenv/shims/bundle exec rails s -e #{env} -d -b 0.0.0.0"
    run_ssh_with(server, console_cmd)
  end
end

desc "Notify Slack deployment was done"
task :notify do
  env = fetch(:rails_env)
  system "curl -L 'yourcustompath"
end

desc "Precompile assets"
task :precompile_assets do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    deploy_to = fetch(:deploy_to)
    execute "cd #{deploy_to}/current/ && RAILS_ENV=#{env} /home/rails/.rbenv/shims/bundle exec rake assets:precompile"
  end
end

desc "Restart delayed jobs"
task :delayed_job_restart do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    deploy_to = fetch(:deploy_to)
    execute "cd #{deploy_to}/current/ && RAILS_ENV=#{env} bin/delayed_job restart"
  end
end

desc "Refresh sitemap"
task :sitemap_refresh do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    deploy_to = fetch(:deploy_to)
    execute "cd #{deploy_to}/current/ && RAILS_ENV=#{env} /home/rails/.rbenv/shims/bundle exec rake sitemap:refresh"
  end
end
