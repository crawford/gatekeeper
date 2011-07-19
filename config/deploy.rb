set :application, "gatekeeper"
set :repository,  "git://github.com/ComputerScienceHouse/gatekeeper.git"

set :scm, :git
set :use_sudo, false
set :deploy_to, "/var/gatekeeper"

role :web, "gatekeeper"
role :app, "gatekeeper"
role :db,  "gatekeeper", :primary => true

set :user, "zuul"

namespace :deploy do
	task :fix_directories, :roles => :app do
		run "mkdir -p /tmp/gatekeeper/service"
		run "mkdir -p /tmp/gatekeeper/site"
		run "mv #{release_path}/software/* /tmp/gatekeeper/service"
		run "mv #{release_path}/site/* /tmp/gatekeeper/site"
		run "rm -rf #{release_path}/*"
		run "rm -rf #{release_path}/.git"
		run "rm -f #{release_path}/.gitignore"
		run "mv /tmp/gatekeeper/* #{release_path}/"
		run "rm -rf /tmp/gatekeeper"
	end

	task :copy_config, :roles => :app do
		run "cp #{shared_path}/database.yml #{release_path}/service/config/database.yml"
	end
end

after 'deploy', 'deploy:fix_directories'
after 'deploy', 'deploy:copy_config'
