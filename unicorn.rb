# Unicorn deps, broken into three sections:

# 1. Render the unicorn config

dep 'unicorn configured' do
  requires 'unicorn.gem', #DONE
           'unicorn config in place' #DONE
end

dep 'unicorn.gem' do #DONE
  installs 'unicorn' => "1.1.3"
  provides "unicorn", "unicorn_rails"
end

dep 'unicorn config in place' do #DONE
  requires 'unicorn config generated' #DONE
  define_var :unicorn_config_within_app, :default => L{ var(:rails_root) / 'config/unicorn.rb' }
  define_var :unicorn_config, :default => L{ var(:unicorn_config_within_app) },
             :message => "Where to render the config (only change this if you'd like to render it elsewhere then symlink it into the app)"
  setup {
    set :absolute_rails_root, var(:rails_root).p
  }
  met? { var(:unicorn_config_within_app).exists? }
  meet { shell "ln -sf #{var :unicorn_config} #{var :unicorn_config_within_app}" }
end

dep 'unicorn config generated' do #DONE
  met? { Babushka::Renderable.new(var(:unicorn_config)).from?(dependency.load_path.parent / "unicorn/unicorn.rb.erb") }
  meet { render_erb 'unicorn/unicorn.rb.erb', :to => var(:unicorn_config) }
end

# 2. Set up how unicorn starts/stops

dep 'unicorn started' do
  requires 'unicorn rc script'
  helper(:unicorn_pid) { var(:app_pid_dir) / 'unicorn.pid' }
  met? {
    unicorn_pid.exist? && sudo("ps `cat #{unicorn_pid}`")
  }
  meet {
    sudo "/etc/init.d/unicorn start"
    30.times do
      if unicorn_pid.exist? then
        break
      else
        sleep 0.1
      end
    end
  }
end

dep 'unicorn rc script' do
  requires 'rcconf.managed'
  met? { shell("rcconf --list").val_for('unicorn') == 'on' }
  meet {
    render_erb 'unicorn/unicorn.init.d.erb', :to => '/etc/init.d/unicorn', :perms => '755', :sudo => true
    sudo 'update-rc.d unicorn defaults'
  }
end

# 3. Watch the workers with monit (for uptime)

dep 'unicorn workers monitored' do
  requires 'monit running'

  helper(:monitrc) { "/etc/monit/conf.d/unicorn_workers.#{var(:app_name)}.monitrc" }
  helper(:master_monitrc) { "/etc/monit/conf.d/unicorn_master.#{var(:app_name)}.monitrc" }

  met? do
    Babushka::Renderable.new(monitrc).from?(dependency.load_path.parent / "monit/unicorn_workers.monitrc.erb") &&
      Babushka::Renderable.new(master_monitrc).from?(dependency.load_path.parent / "monit/unicorn_master.monitrc.erb")
  end
  meet do
    render_erb "monit/unicorn_workers.monitrc.erb", :to => monitrc, :sudo => true
    render_erb "monit/unicorn_master.monitrc.erb", :to => master_monitrc, :sudo => true
  end

  after { sudo "monit reload" }
end
