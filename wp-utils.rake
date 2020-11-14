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

desc "Notify Slack deployment was done"
task :notify do
  env = fetch(:rails_env)
  system "curl -L 'https://stuntcoders.com/deploy/notify.php?project=posterstar&server=#{env}'"
end

desc "Restart delayed jobs"
task :set_permissions do
  on roles(:app) do |server|
    execute "chmod 750 #{release_path} && chown posterstarwebsit:nobody #{release_path}"
  end
end

desc "Set basics like robots and htaccess"
task :set_basics do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    deploy_to = fetch(:deploy_to)
    execute "cd #{deploy_to}/current/ && mv robots.txt.#{env} robots.txt && mv .htaccess.#{env} .htaccess"
  end
end

desc "Cleanup files like databases, .git and similar"
task :cleanup do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    deploy_to = fetch(:deploy_to)
    execute "cd #{deploy_to}/current/ && rm -rf *.sql && rm -f *.zip"
  end
end

desc "Download database"
task :get_database do
  on roles(:app) do |server|
    env = fetch(:rails_env)
    user = fetch(:user)
    deploy_to = fetch(:deploy_to)

    execute "cd #{deploy_to}/current/ && wp db export #{env}.sql"
    system "scp #{user}@#{server}:#{current_path}/#{env}.sql #{env}.sql"
    execute "rm -rf *.sql"
  end
end

desc 'Clear caches'
task :clear_caches do
  # Clear OPCache
  execute :touch, "#{fetch(:deploy_to)}/php-fpm.service"

  within current_path do
    # Clear WP-cache
    execute :wp, :cache, :flush
    # Clear any other cache by running do_action method
    execute :wp, :eval, '"do_action( \'cache_flush\' );"'
  end
end
