# dont't prompt for host key verfication (if any)
template "/home/vagrant/.ssh/config" do
  user "vagrant"
  group "vagrant"
  mode "0600"
  source "config"
end

execute "add docker repo" do
  not_if "test -f /etc/apt/sources.list.d/docker.list"
  command "wget -q -O - https://get.docker.io/gpg | apt-key add - && echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list"
end

execute "apt-get-update" do
  command "apt-get update"
  ignore_failure true
end

# install necessary software
%w(
bash-completion
git
vim
nano
screen
tmux
lxc-docker
).each { | pkg | package pkg }


# disable the iptables firewall
service "iptables" do
  action :disable
end

# flush iptables
execute "iptables -F"


# copy .bashrc from template
template "/home/vagrant/.bashrc.git" do
  user "vagrant"
  group "users"
  mode "0644"
  source ".bashrc.git"
end

execute "load bash git prompt" do
  user "vagrant"
  command "echo 'source ~/.bashrc.git' >> /home/vagrant/.bashrc"
end

execute "load bash aliases" do
  user "vagrant"
  command "cat /vagrant/vagrant/templates/default/.bashrc.aliases >> /home/vagrant/.bashrc"
end

execute "add user vagrant to group docker" do
  user "root"
  command "usermod -a -G docker vagrant"
end

# Start Docker
service "docker" do
  provider Chef::Provider::Service::Upstart
  supports :restart => true
  action [ :enable, :start ]
end

# don't start puppet
service "puppet" do
  supports :restart => true
  action [ :disable]
end

# allow docker access from outside (with eg. boot2docker)
execute "allow docker access from outside" do
  not_if "grep '-H tcp://0.0.0.0:4243' /etc/default/docker"
  command "sed -i 's/#DOCKER_OPTS=\"/DOCKER_OPTS=\"-H tcp:\\\/\\\/0.0.0.0:4243 -H unix:\\\/\\\/\\\/var\\\/run\\\/docker.sock /g'  /etc/default/docker"
  notifies :restart, "service[docker]"
end



