include Partition::Utils

use_inline_resources if defined?(use_inline_resources)

def whyrun_supported?
  true
end

action :create do
  device = new_resource.device
  name = new_resource.name
  size = new_resource.size
  disk_infos, part_infos = scan_existing(device)
  create_partition(disk_infos, part_infos, name, size) unless @current_resource.exists
end

action :remove do
  device = new_resource.device
  name = new_resource.name
  disk_infos, part_infos = scan_existing(device)
  remove_partition(disk_infos, part_infos, name) if @current_resource.exists
end






def load_current_resource
  @current_resource = Chef::Resource::Partition.new(@new_resource.name)
  @current_resource.name(@new_resource.name)
  if part_exists?(@current_resource.name)
    @current_resource.exists = true
  end
end
