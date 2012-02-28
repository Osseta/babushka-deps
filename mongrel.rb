dep 'mongrel.gem' do
  provides 'mongrel_rails'
end

dep 'monit mongrels configured' do
  requires 'mongrel.gem',
           'monit running'
  helper(:monitrc) { "/etc/monit/conf.d/mongrel.#{var(:app_name)}.monitrc" }
  met? { Babushka::Renderable.new(monitrc).from?(dependency.load_path.parent / "mongrel/mongrels.monitrc.erb") }
  meet { render_erb "mongrel/mongrels.monitrc.erb", :to => monitrc, :sudo => true }
  after {
    sudo "monit reload"
    sudo "monit restart all -g mongrel_#{var(:app_name)}"
  }
end
