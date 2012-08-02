name             "homebrew"
maintainer       "Graeme Mathieson"
maintainer_email "mathie@woss.name"
license          "Apache 2.0"
description      "Install Homebrew and use it as your package provider in Mac OS X"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "1.0.1"
recipe           "homebrew", "Install Homebrew"
%w{ mac_os_x mac_os_x_server }.each do |platform|
  supports platform
end
