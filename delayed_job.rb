dep 'delayed job running' do
  requires 'daemons.gem', #DONE
           'delayed job monit configured' #DONE
  # can we check they're actually running?
end

dep 'delayed job monit configured' do
  helper(:monitrc) { "/etc/monit/conf.d/dj.#{var(:app_name)}.monitrc" }
  met? { Babushka::Renderable.new(monitrc).from?(dependency.load_path.parent / "delayed_job/dj.monitrc.erb") }
  meet { render_erb "delayed_job/dj.monitrc.erb", :to => monitrc, :sudo => true }
  after {
    sudo "monit reload"
    sudo "monit restart all -g dj_#{var(:app_name)}"
  }
end

dep 'daemons.gem' do
  provides []
end
