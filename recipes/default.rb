user node[:homebrew][:user] do
  gid Etc.getgrnam('staff').gid
end

execute "install homebrew" do
  command "curl -sfL https://github.com/mxcl/homebrew/tarball/master | tar zx -m --strip 1"
  user node[:homebrew][:user]
  cwd "/usr/local"
  not_if { File.exist? '/usr/local/bin/brew' }
end

execute "chown homebrew Cellar" do
  command "chown -R #{node[:homebrew][:user]}:staff /usr/local/Cellar"
end

package 'git'

execute "update homebrew from github" do
  command "/usr/local/bin/brew update || true"
end

