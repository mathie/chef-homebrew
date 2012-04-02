# Chef package provider for Homebrew

require 'chef/provider/package'
require 'chef/resource/package'
require 'chef/platform'

class Chef
  class Provider
    class Package
      class Homebrew < Package
        def load_current_resource
          @current_resource = Chef::Resource::Package.new(@new_resource.name)
          @current_resource.package_name(@new_resource.package_name)
          @current_resource.version(current_linked_version)

          @current_resource
        end

        def install_package(name, version)
          unless @current_resource.version == version
            # If git is not installed, homebrew can't look up other
            # versions. If a node requires a specific version of git,
            # the latest version of git is installed then used to look
            # up older versions of git due to this limitation of
            # homebrew.
            install_package(name, :latest) if name == 'git' and @current_resource.version.nil?

            checkout_formula_for(name, version)

            brew('unlink', name) unless installed_versions.empty?

            action = installed_versions.include?(version) ? 'link' : 'install'
            brew(action, name)
          end
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

        protected

        def brew(*args)
          run_command_with_systems_locale(
            :command => "brew #{args.join(' ')}"
          )
        end

        def checkout_formula_for name, version
          command = if version == :latest
                      "git checkout HEAD /usr/local/Library/Formula/#{name}.rb"
                    else
                      match = get_response_from_command("brew versions #{name}").match(/^#{version}\s+(git.+)$/)
                      if match
                        match[1]
                      else
                        raise Chef::Exceptions::Package, "Homebrew doesn't know anything about version #{version} of #{name}"
                      end
                    end

          # Dir for the git repo
          directory = ::File.dirname(command.split(/\s/).last)

          run_command_with_systems_locale(
            :command => command,
            :cwd => directory
          )
        end

        def installed_versions
          # 2..-1 excludes ['.', '..']
          Dir.entries("/usr/local/Cellar/#{@new_resource.package_name}")[2..-1]
        rescue Errno::ENOENT
          []
        end

        def current_linked_version
          ::File.readlink("/usr/local/Library/LinkedKegs/#{@new_resource.package_name}").split(/\//).last
        rescue Errno::ENOENT
          nil
        end

        def candidate_version
          get_version_from_command("brew info #{@new_resource.package_name} | awk '/^#{@new_resource.package_name} / { print $2 }'")
        end

        def get_version_from_command(command)
          version = get_response_from_command(command).chomp
          version.empty? ? nil : version
        end

        # Nicked from lib/chef/package/provider/macports.rb and tweaked
        # slightly.
        def get_response_from_command(command)
          output = nil
          status = popen4(command) do |pid, stdin, stdout, stderr|
            begin
              output = stdout.read
            rescue Exception => e
              raise Chef::Exceptions::Package, "Could not read from STDOUT on command: #{command}\nException: #{e.inspect}"
            end
          end
          unless (0..1).include? status.exitstatus
            raise Chef::Exceptions::Package, "#{command} failed - #{status.inspect}"
          end
          output
        end
      end
    end
  end
end

Chef::Platform.set :platform => :mac_os_x, :resource => :package, :provider => Chef::Provider::Package::Homebrew
