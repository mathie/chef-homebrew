actions :install, :upgrade, :remove, :purge

attribute :package_name, :kind_of => String, :name_attribute => true
attribute :version, :default => nil
attribute :options, :kind_of => String
