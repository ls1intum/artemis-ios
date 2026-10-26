require 'open3'
require 'tmpdir'
require 'rbconfig'

script = File.expand_path('../check-build-warnings.rb', __dir__)
cases = {
  'clean build' => ["** BUILD SUCCEEDED **\nCompiling Deprecations.swift\n", true],
  'deprecated filename' => ["Compiling Deprecated.swift\n", true],
  'SDK export deprecation' => ['Command line name app-store is deprecated. Use app-store-connect instead.', false],
  'compiler deprecation' => ['/src/App.swift:9:4: warning: oldAPI is deprecated', false],
  'destination warning' => ['--- xcodebuild: WARNING: Using the first of multiple matching destinations:', false],
  'colored warning' => ["\e[35m/src/App.swift:9:4: warning: unused value\e[0m", false],
  'metadata warning' => ['appintentsmetadataprocessor[123] warning: Metadata extraction skipped', false]
}

Dir.mktmpdir('artemis-warning-gate') do |directory|
  cases.each do |name, (text, success)|
    path = File.join(directory, 'build.log')
    File.write(path, text)
    _, error, status = Open3.capture3(RbConfig.ruby, script, path)
    raise "#{name}: unexpected exit status: #{error}" unless status.success? == success
    raise "#{name}: failed for an unrelated reason: #{error}" if !success && !error.include?('Build emitted')
  end
  _, error, status = Open3.capture3(RbConfig.ruby, script, File.join(directory, 'missing', '*.log'))
  raise 'Missing logs were accepted' if status.success?
  raise "Missing logs failed for an unrelated reason: #{error}" unless error.include?('No build logs found')
end
puts '8 build-warning gate cases passed.'
