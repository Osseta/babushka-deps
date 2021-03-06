# Installs and configures monit. Like a boss.

dep 'monit running' do #DONE
  requires 'monit'
  requires_when_unmet 'monit startable'
  met? { (status = sudo("monit status")) && status[/uptime/] }
  meet { sudo "/etc/init.d/monit start" }
end

dep 'monit', :template => 'managed'

dep 'monit startable' do
  requires 'monitrc configured', 'monit config is where we expect'
  met? { sudo "grep 'startup=1' /etc/default/monit" }
  meet { sudo "sed -i s/startup=0/startup=1/ /etc/default/monit" }
end

dep 'monitrc configured' do
  define_var :monit_frequency, :default => 30
  define_var :monit_port, :default => 9111
  define_var :monit_included_dir, :default => '/etc/monit/conf.d/*.monitrc'
  met? { Babushka::Renderable.new("/etc/monit/monitrc").from?(dependency.load_path.parent / "monit/monitrc.erb") }
  meet { render_erb "monit/monitrc.erb", :to => "/etc/monit/monitrc", :sudo => true, :perms => '700' }
end

dep 'monit config is where we expect' do
  met? { "/etc/default/monit".p.exists? }
  meet { shell "echo startup=0 >> /etc/default/monit" }
end
