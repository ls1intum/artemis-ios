require 'open3'
require 'tmpdir'
require 'rbconfig'

wrapper = File.expand_path('../xcodebuild-with-diagnostics.sh', __dir__)
gate = File.expand_path('../check-build-warnings.rb', __dir__)

Dir.mktmpdir('artemis-xcodebuild-diagnostics') do |directory|
  fake_xcodebuild = File.join(directory, 'xcodebuild')
  File.write(fake_xcodebuild, <<~SH)
    #!/bin/sh
    printf '%s\\n' "$@" > "$ARTEMIS_TEST_ARGUMENT_LOG"
    printf '%s\\n' '** BUILD SUCCEEDED **'
    if [ "$ARTEMIS_TEST_EMIT_WARNING" = 1 ]; then
      printf '%s\\n' '--- xcodebuild: WARNING: Using the first of multiple matching destinations:' >&2
    fi
    exit "$ARTEMIS_TEST_EXIT_STATUS"
  SH
  File.chmod(0755, fake_xcodebuild)

  log = File.join(directory, 'build.log')
  argument_log = File.join(directory, 'arguments')
  env = {
    'PATH' => "#{directory}:#{ENV.fetch('PATH')}",
    'ARTEMIS_TEST_BUILD_LOG' => log,
    'ARTEMIS_TEST_ARGUMENT_LOG' => argument_log,
    'ARTEMIS_TEST_EMIT_WARNING' => '0',
    'ARTEMIS_TEST_EXIT_STATUS' => '0'
  }
  arguments = ['-scheme', 'Scheme with spaces', 'SETTING=a $literal; value', '']
  pipeline = ['bash', '-o', 'pipefail', '-c', '"$@" | tee "$ARTEMIS_TEST_BUILD_LOG"', 'diagnostics-test', wrapper, *arguments]

  _, error, status = Open3.capture3(env, *pipeline)
  raise "Clean build failed: #{error}" unless status.success?
  raise 'xcodebuild arguments changed' unless File.read(argument_log) == arguments.map { |argument| "#{argument}\n" }.join
  _, error, status = Open3.capture3(RbConfig.ruby, gate, log)
  raise "Clean build was rejected: #{error}" unless status.success?

  _, _, status = Open3.capture3(env.merge('ARTEMIS_TEST_EXIT_STATUS' => '42'), *pipeline)
  raise "xcodebuild exit status changed to #{status.exitstatus}" unless status.exitstatus == 42

  _, error, status = Open3.capture3(env.merge('ARTEMIS_TEST_EMIT_WARNING' => '1'), *pipeline)
  raise "Successful warning build failed unexpectedly: #{error}" unless status.success?
  _, error, status = Open3.capture3(RbConfig.ruby, gate, log)
  raise 'Warning emitted on stderr was accepted by the build-log gate' if status.success?
  raise "Warning failed for an unrelated reason: #{error}" unless error.include?('Build emitted 1 warning diagnostics.')
end
puts '4 xcodebuild diagnostics pipeline cases passed.'
