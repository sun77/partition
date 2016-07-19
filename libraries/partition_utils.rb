module Partition
  # Functions for partition management
  module Utils
    module_function

    def scan_existing(disk)
      cmd = Mixlib::ShellOut.new("parted -m #{disk} unit s print free")
      cmd.run_command
      part_keys = %w(id start stop size fs name flags)
      disk_keys = %w(dev size conn lss pss label model)
      partitions = cmd.stdout.split($INPUT_RECORD_SEPARATOR)[2..-1].map { |x| x.split(':') }
      disk = cmd.stdout.split($INPUT_RECORD_SEPARATOR)[1].split(':')
      [Hash[disk_keys.zip(disk)], partitions.map { |x| Hash[part_keys.zip(x)] }]
    end

    # Find sector limits in MB
    def find_limits(free_part_infos, size)
      start_part = nil
      end_part = nil
      minimal_header = 2048
      free_part_infos.each do |p|
        size_part = p['start'].to_i < minimal_header ? p['size'].to_i - minimal_header : p['size'].to_i
        next if size_part < size.to_i
        start_part = p['start'].to_i < minimal_header ? minimal_header : p['start']
        end_part = start_part.to_i + size.to_i - 1
        break
      end
      raise 'not enough free space to create the partition' if start_part.nil? || end_part.nil?
      [start_part, end_part]
    end

    def size_in_sectors(sector_size, value)
      alignment = 2048
      result =
        case value
        when /M$/ then value.to_i * 1000 * 1000 / sector_size.to_i
        when /G$/ then value.to_i * 1000 * 1000 * 1000 / sector_size.to_i
        when /s/  then value.to_i
        else
          raise "Could not convert #{value} to sectors"
        end
      # We return the closest integer multiple of the aligment value
      result - result % alignment
    end

    # Check if partition exist
    def exists?(part_infos, name)
      answer = false
      part_infos.each do |p|
        if p['name'].eql? name
          answer = true
          break
        end
      end
      answer
    end

    # Create partition
    def create_partition(all_infos, name, size)
      part_start, part_end = nil

      # Check disk label gpt
      raise 'Unsuported disk label (Only gpt is supported)' unless disk_infos['label'].eql? 'gpt'
      free_part_infos = part_infos.select { |p| p['fs'].eql? 'free;' }
      part_start, part_end = find_limits(free_part_infos, size_in_sectors(disk_infos['pss'], size))

      execute "Creation of #{name} partition" do
        command "parted #{disk_infos['dev']} --script unit s -- mkpart #{name} #{part_start} #{part_end}"
        action :run
      end
    end

    # Delete partition
    def remove_partition(all_infos, name)
      id = id_by_name(disk, name)
      execute "Deletion of #{name} partition" do
        command "parted #{disk} --script -- rm #{id}"
        action :run
      end
    end

    # Format partition
    def format_partition(disk, name, fs)
      id = id_by_name(disk, name)
      execute "Format of #{name} partition to #{fs}" do
        command "mkfs.#{fs} #{disk}#{id}"
        action :run
      end
    end

    # Set flag
    def sefflag_partition(disk, name, flag_name)
      id = id_by_name(disk, name)
      execute "Format of #{name} partition to #{fs}" do
        command "parted #{disk} --script -- set #{id} #{flag_name} on"
        action :run
      end
    end

    def id_by_name(disk, name)
      part_infos = scan_existing(disk)[1]
      part_infos.select { |p| p['name'].eql? name }[0]['id']
    end
  end
end
