require 'fileutils'
require 'open3'
require 'tmpdir'

source = File.expand_path('../setup-ci-ruby.sh', __dir__)
Dir.mktmpdir('artemis-ruby-setup') do |directory|
  FileUtils.mkdir_p(File.join(directory, 'scripts'))
  FileUtils.cp(source, File.join(directory, 'scripts/setup-ci-ruby.sh'))
  File.write(File.join(directory, 'Gemfile.lock'), "BUNDLED WITH\n   2.6.6\n")
  File.write(File.join(directory, '.ruby-version'), "4.0.9\n")
  binary_path = File.join(directory, 'rbenv/versions/4.0.9/bin')
  tools_path = File.join(directory, 'tools')
  FileUtils.mkdir_p([binary_path, tools_path])
  File.write(File.join(tools_path, 'rbenv'), "#!/bin/sh\nprintf '%s\\n' \"$ARTEMIS_TEST_RBENV_ROOT\"\n")
  File.chmod(0755, File.join(tools_path, 'rbenv'))
  %w[ruby gem bundle].each do |name|
    path = File.join(binary_path, name)
    File.write(path, "#!/bin/sh\nprintf '%s %s\\n' '#{name}' \"$*\" >> \"$ARTEMIS_TEST_COMMAND_LOG\"\n")
    File.chmod(0755, path)
  end
  path_file = File.join(directory, 'github-path')
  command_log = File.join(directory, 'commands')
  env = {
    'PATH' => "#{tools_path}:/usr/bin:/bin",
    'ARTEMIS_TEST_RBENV_ROOT' => File.join(directory, 'rbenv'),
    'ARTEMIS_TEST_COMMAND_LOG' => command_log,
    'GITHUB_PATH' => path_file
  }
  _, error, status = Open3.capture3(env, 'bash', File.join(directory, 'scripts/setup-ci-ruby.sh'), chdir: directory)
  raise "Existing Ruby setup failed: #{error}" unless status.success?
  raise 'Workflow PATH does not select the required Ruby' unless File.read(path_file).lines.map(&:strip).include?(binary_path)
  commands = File.read(command_log)
  raise 'Locked Bundler was not installed' unless commands.include?('gem install bundler --version 2.6.6 --no-document')
  raise 'Gems were not installed' unless commands.include?("bundle install\n")

  File.write(File.join(directory, '.ruby-version'), "../../invalid\n")
  _, error, status = Open3.capture3(env, 'bash', File.join(directory, 'scripts/setup-ci-ruby.sh'), chdir: directory)
  raise 'Unsafe Ruby version was accepted' if status.success?
  raise "Invalid version failed for an unrelated reason: #{error}" unless error.include?('numeric Ruby release')
end
puts '2 Ruby provisioning cases passed.'
