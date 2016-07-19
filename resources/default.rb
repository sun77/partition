actions :create, :remove :format :setflag
default_action :create

state_attrs :name

# Resource properties
attribute :name, name_attribute: true, kind_of: String, required: true
attribute :size, kind_of: Integer, required: true
attribute :file_system, kind_of: String, required: true
attribute :flags, kind_of: String

attr_accessor :exists
