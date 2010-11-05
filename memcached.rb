# Sets up memcached and watches using monit

dep 'memcached running' do
  requires 'memcached configured', #DONE
           'memcached monit configured' #DONE
end

dep 'memcached configured' do
  requires 'memcached.managed' #DONE
  define_var :memcached_port, :default => '11211'
  define_var :memcached_listen_ip, :default => '0.0.0.0'
  met? { sudo "grep 'Generated by babushka' /etc/memcached.conf" }
  meet { render_erb "memcached/memcached.conf.erb", :to => '/etc/memcached.conf', :sudo => true }
end

dep 'memcached.managed'

dep 'memcached monit configured' do
  requires 'monit running'
  helper(:monitrc) { "/etc/monit/conf.d/memcached.monitrc" }
  met? { sudo "grep 'Generated by babushka' #{monitrc}" }
  meet { render_erb "memcached/memcached.monitrc.erb", :to => monitrc, :sudo => true }
  after {
    sudo "monit reload"
    sudo "monit restart all -g memcached"
  }
end