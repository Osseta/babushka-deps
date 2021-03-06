# Sets up sphinx v0.9.8, and thinkingsphinx to connect to it.

dep 'sphinx configured' do
  requires 'sphinx.src', #DONE
           'sphinx directory setup', #DONE
           'sphinx yml in place', #DONE
           'sphinx indexed' #DONE
  define_var :ts_generated_config,
             :default => L{ var(:rails_root) / "config/#{var(:rails_env)}.sphinx.conf" },
             :message => "Where to tell thinkingsphinx to render the sphinx config"
end

dep 'sphinx.src' do #DONE
  source "http://www.sphinxsearch.com/files/sphinx-0.9.8.tar.gz"
  provides 'search', 'searchd', 'indexer'
end

dep 'sphinx directory setup' do #DONE
  define_var :sphinx_dir, :default => '/var/sphinx'
  met? { (var(:sphinx_dir) / 'indexes').exists? && var(:sphinx_dir).p.writable_real? }
  meet {
    sudo "mkdir -p #{var(:sphinx_dir) / 'indexes'}"
    sudo("chown -R #{var(:username)}:#{var(:username)} #{var(:sphinx_dir)}")
  }
end

dep 'sphinx yml in place' do #DONE
  requires 'sphinx yml generated' #DONE
  define_var :sphinx_config_within_app, :default => L{ var(:rails_root) / 'config/sphinx.yml' }
  define_var :sphinx_config, :default => L{ var(:sphinx_config_within_app) },
             :message => "Where to render the config (only change this if you'd like to render it elsewhere then symlink it into the app)"
  met? { var(:sphinx_config_within_app).exists? }
  met? { shell "ln -sf #{var(:sphinx_config)} #{var(:sphinx_config_within_app)}" }
end

dep 'sphinx yml generated' do #DONE
  define_var :sphinx_port, :default => 3312
  define_var :sphinx_mem_limit, :default => '384M'
  met? { Babushka::Renderable.new(var(:sphinx_config)).from?(dependency.load_path.parent / "sphinx/sphinx.yml.erb") }
  meet { render_erb 'sphinx/sphinx.yml.erb', :to => var(:sphinx_config) }
end

dep 'sphinx indexed' do
  met? { var(:ts_generated_config).p.exists? }
  meet {
    shell "mkdir -p #{File.dirname(var(:ts_generated_config))}"
    in_dir(var(:rails_root)) { shell "rake RAILS_ENV=#{var :rails_env} thinking_sphinx:index", :log => true }
  }
end

dep 'sphinx monit configured' do
  requires 'monit running' #DONE
  helper(:monitrc) { "/etc/monit/conf.d/sphinx.#{var(:app_name)}.monitrc" }
  met? { Babushka::Renderable.new(monitrc).from?(dependency.load_path.parent / "sphinx/sphinx.monitrc.erb") }
  meet { render_erb "sphinx/sphinx.monitrc.erb", :to => monitrc, :sudo => true }
  after {
    sudo "monit reload"
    sudo "monit restart sphinx_#{var(:app_name)}"
  }
end
