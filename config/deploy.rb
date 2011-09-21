set :application, "gatekeeper"
set :repository,  "git://github.com/ComputerScienceHouse/gatekeeper.git"

set :scm, :git
set :use_sudo, false
set :deploy_to, "/var/gatekeeper"

role :web, "gatekeeper.csh.rit.edu"
role :app, "gatekeeper.csh.rit.edu"
role :db,  "gatekeeper.csh.rit.edu", :primary => true

set :user, "zuul"

namespace :deploy do
	task :fix_directories, :roles => :app do
		run "mkdir -p /tmp/gatekeeper/software"
		run "mv #{release_path}/software/* /tmp/gatekeeper/software"
		run "rm -rf #{release_path}/*"
		run "rm -rf #{release_path}/.git"
		run "rm -f #{release_path}/.gitignore"
		run "mv /tmp/gatekeeper/* #{release_path}/"
		run "rm -rf /tmp/gatekeeper"
	end

	task :copy_config, :roles => :app do
		run "cp #{shared_path}/database.yml #{release_path}/software/config/database.yml"
		run "cp #{shared_path}/servers.yml #{release_path}/software/config/servers.yml"
		run "cp #{shared_path}/ldap.yml #{release_path}/software/config/ldap.yml"
	end

	task :restart_unicorn, :roles => :app do
		if File.exists?('/var/tmp/unicorn.pid')
			File.open('/var/tmp/unicorn.pid', 'r') do |file|
				pid = file.read.to_i
				run "kill #{pid}"
			end
		end
		run "source /home/zuul/.zshrc; unicorn -c #{release_path}/software/site/config/unicorn.rb -D"
	end
end

namespace :bundler do
	task :create_symlink, :roles => :app do
		shared_dir = File.join(shared_path, 'bundle')
		release_dir = File.join(release_path, '.bundle')
		run "mkdir -p #{shared_dir} && ln -s #{shared_dir} #{release_dir}"
	end

	task :install, :roles => :app do
		run "cd #{release_path} && bundle install"

		on_rollback do
			if previous_release
				run "cd #{previous_release} && bundle install"
			else
				logger.important "no previous release to rollback to, rollback of bundler:install skipped"
			end
		end
	end

	task :bundle_new_release, :roles => :db do
		bundler.create_symlink
		bundler.install
	end
end

#after 'deploy', 'deploy:fix_directories'
after 'deploy', 'deploy:copy_config'
after 'deploy', 'deploy:restart_unicorn'
#after "deploy:rollback:revision", "bundler:install"
#after "deploy:update_code", "bundler:bundle_new_release"
