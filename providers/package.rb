# Chef package provider for Homebrew

require 'chef/mixin/shell_out'
include Chef::Mixin::ShellOut

action :install do
  # If we specified a version, and it's not the current version, move to the specified version
  if @new_resource.version != nil && @new_resource.version != @current_resource.version
    install_version = @new_resource.version
  # If it's not installed at all, install it
  elsif @current_resource.version == nil or @current_resource.version.empty?
    install_version = candidate_version
  end
  
  if install_version
    Chef::Log.info("Installing #{@new_resource} version #{install_version}")
    status = install_package(@new_resource.package_name, install_version)
    if status
      @new_resource.updated_by_last_action(true)
    end
  else
    Chef::Log.debug("Skipping install of #{@current_resource}, version #{@current_resource.version.inspect} is already installed")
  end
end

action :upgrade do
  if @current_resource.version != candidate_version
    orig_version = @current_resource.version || "uninstalled"
    Chef::Log.info("Upgrading #{@new_resource} version from #{orig_version} to #{candidate_version}")
    status = upgrade_package(@new_resource.package_name, candidate_version)
    if status
      @new_resource.updated_by_last_action(true)
    end
  end
end

action :remove do
  if removing_package?
    Chef::Log.info("Removing #{@new_resource}")
    remove_package(@current_resource.package_name, @new_resource.version)
    @new_resource.updated_by_last_action(true)
  else
  end
end

def removing_package?
  if @current_resource.version.nil?
    false # nothing to remove
  elsif @new_resource.version.nil?
    true # remove any version of a package
  elsif @new_resource.version == @current_resource.version
    true # remove the version we have
  else
    false # we don't have the version we want to remove
  end
end

def load_current_resource
  @current_resource = Chef::Resource::Package.new(@new_resource.name)
  @current_resource.package_name(@new_resource.package_name)
  @current_resource.version(current_installed_version)

  @current_resource
end

def install_package(name, version)
  brew('install', name)
end

# Homebrew doesn't really have a notion of upgrading packages, just
# install the latest version?
def upgrade_package(name, version)
  install_package(name, version)
end

def remove_package(name, version)
  brew('uninstall', name)
end

# Homebrew doesn't really have a notion of purging, so just remove.
def purge_package(name, version)
  remove_package(name, version)
end

def brew(*args)
  shell_out!("brew #{args.join(' ')}")
end

def current_installed_version
  @current_installed_version ||= begin
    p = shell_out!("brew list --versions | awk '/^#{@new_resource.package_name} / { print $2 }'")
    p.stdout.strip
  rescue Chef::Exceptions::ShellCommandFailed
  end
end

def candidate_version
  @candidate_version ||= begin
    p = shell_out!("brew info #{@new_resource.package_name} | awk '/^#{@new_resource.package_name} / { print $2 }'")
    p.stdout.strip
  rescue Chef::Exceptions::ShellCommandFailed
  end
end
