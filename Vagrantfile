# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'json'


Vagrant.configure("2") do |config|
  # All Vagrant configuration is done here. The most common configuration
  # options are documented and commented below. For a complete reference,
  # please see the online documentation at vagrantup.com.

  # Every Vagrant virtual environment requires a box to build off of.
  config.vm.box = "cloudVM"
  config.omnibus.chef_version = :latest
  config.vm.network :private_network, ip: "192.168.56.101"
  config.vm.network :forwarded_port, guest: 80, host: 8080
  config.vm.provision :shell, :inline => 'apt-get update'


  VAGRANT_JSON = JSON.parse(Pathname(__FILE__).dirname.join('nodes', 'chef_solo_env.json').read)

    config.vm.provision :chef_solo do |chef|
      chef.cookbooks_path = ["site-cookbooks", "cookbooks"]
      chef.roles_path = "roles"
      chef.data_bags_path = "data_bags"
      chef.provisioning_path = "/tmp/vagrant-chef"

      # You may also specify custom JSON attributes:
             chef.run_list = VAGRANT_JSON.delete('run_list')
                   chef.json = VAGRANT_JSON
 end
end
