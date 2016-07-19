#
# Cookbook Name:: partition
# Recipe:: default
#
# Copyright (c) 2016 The Authors, All Rights Reserved.

include_recipe 'parted'

node['disk'] = {
  '/dev/sda' => {
    label: 'gpt'
    partitions: [
      {
        name: 'data',
        size: '300G',
        filesystem: 'ext4',
        mountpoint: '/var/opt',
        mount_options: 'defaults',
      },
      {
        name: 'log',
        size: '20G',
        filesystem: 'ext4',
        mountpoint: '/var/log',
        mount_options: 'defaults',
      },
    ]
  }, 
  '/dev/sdb' => {
    label: 'gpt'
    partitions: [
      {
        name: 'toto',
        size: '300G',
        filesystem: 'ext4',
        mountpoint: '/var/toto',
        mount_options: 'defaults',
      },
      {
        name: 'titi',
        size: '20G',
        filesystem: 'ext4',
        mountpoint: '/var/titi',
        mount_options: 'defaults',
      },
    ]
  },
}

node['disk'].each do |dev, properties|
  disk dev do
    label properties['label']
    partitions properties['partition']
  end

  properties['partition'].each do |name, opts|
    filesystem name do
      fstype opts['fstype']
      device "#{dev}#{opts['id']}"
      mount opts['mount']
      options opts['mount_options']
      mkfs_options opts['mkfs_options']
      action [:create, :enable, :mount]
    end
end





node['parted_hpc']['disk'].each do |dev, props|
  parted_disk dev do
    label_type props['disklabel']
    action :mklabel
  end
  index = 1
  props['volume'].each do |opts|
    provider partition #### !!!! #### (dev, opts)
    parted_disk dev do
      part_type opts['type']
      file_system opts['filesystem']
      part_start
      part_end
      action :mkpart
    end
    parted_disk "#{dev}#{index}" do
      action :mkfs
    end
    index += 1
  end
end




node['parted_hpc']['disk'].each do |dev, props|
  disk_label dev do
    label_type props['disklabel']
    action :mklabel
  end

  props['volume'].each do |opts|
    partition dev do
      part_type opts['type']
      file_system opts['filesystem']
      size opts['size']
      action [:create, :format]
    end
  end
end



partition 'LABEL' do
  disk '/dev/sda'
  part_type 'primary'
  file_system 'ext4'
  size '30G'
  action :create
end