require 'fileutils'
require 'json'
require 'open3'
require 'tmpdir'
require 'rbconfig'

SOURCE = File.expand_path('../lint.sh', __dir__)

def write_binary(path, version, label, exit_status = 0)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, <<~SH)
    #!/bin/sh
    if [ "$1" = --version ]; then
      printf '%s\\n' '#{version}'
      exit 0
    fi
    pwd > "$ARTEMIS_TEST_WORKING_DIRECTORY"
    printf '%s\\n' '#{label}' "$@" > "$ARTEMIS_TEST_LINT_ARGUMENTS"
    exit #{exit_status}
  SH
  File.chmod(0755, path)
end

def check_case(name, identity: 'swiftlintplugins', version: '0.65.1', binaries: [], fallback: nil, expected: nil, exit_status: 0)
  Dir.mktmpdir('artemis-lint') do |directory|
    FileUtils.mkdir_p(File.join(directory, 'scripts'))
    FileUtils.cp(SOURCE, File.join(directory, 'scripts/lint.sh'))
    File.write(File.join(directory, '.swiftlint.yml'), "included: []\n")
    resolved = File.join(directory, 'Artemis.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved')
    FileUtils.mkdir_p(File.dirname(resolved))
    File.write(resolved, JSON.generate('pins' => [{ 'identity' => identity, 'state' => { 'version' => version } }]))
    binaries.each do |relative_path, binary_version, label|
      write_binary(File.join(directory, relative_path), binary_version, label, exit_status)
    end
    tools = File.join(directory, 'tools')
    FileUtils.mkdir_p(tools)
    FileUtils.ln_s(RbConfig.ruby, File.join(tools, 'ruby'))
    write_binary(File.join(tools, 'swiftlint'), fallback, 'fallback', exit_status) if fallback
    argument_log = File.join(directory, 'arguments')
    working_directory_log = File.join(directory, 'working-directory')
    env = {
      'PATH' => "#{tools}:/usr/bin:/bin",
      'BUILD_DIR' => File.join(directory, 'active-derived-data/Build/Products'),
      'ARTEMIS_TEST_LINT_ARGUMENTS' => argument_log,
      'ARTEMIS_TEST_WORKING_DIRECTORY' => working_directory_log
    }
    # BUILD_DIR's real parent directories must exist before traversing ../...
    FileUtils.mkdir_p(env.fetch('BUILD_DIR'))
    arguments = ['Sources/With spaces.swift', '--reporter', 'json', 'literal $value; text', '']
    _, error, status = Open3.capture3(env, 'sh', File.join(directory, 'scripts/lint.sh'), *arguments, chdir: '/tmp')
    if expected
      raise "#{name}: unexpected exit #{status.exitstatus}: #{error}" unless status.exitstatus == exit_status
      expected_arguments = [expected, 'lint', '--strict', '--config', File.join(directory, '.swiftlint.yml'), *arguments]
      raise "#{name}: binary selection or arguments changed" unless File.read(argument_log) == expected_arguments.map { |argument| "#{argument}\n" }.join
      raise "#{name}: wrong working directory" unless File.realpath(File.read(working_directory_log).strip) == File.realpath(directory)
    else
      raise "#{name}: accepted unavailable or mismatched SwiftLint" if status.success?
      raise "#{name}: ran a mismatched binary" if File.exist?(argument_log)
      raise "#{name}: failed for an unrelated reason: #{error}" unless error.include?('error:') && error.include?('SwiftLint')
    end
  end
end

modern = 'swiftlintplugins/SwiftLintBinary/SwiftLintBinary.artifactbundle/macos/swiftlint'
legacy = 'swiftlint/SwiftLintBinary/SwiftLintBinary.artifactbundle/swiftlint-0.55.1-macos/bin/swiftlint'
active = 'active-derived-data/SourcePackages/artifacts'
tests = 'build/test-derived-data/SourcePackages/artifacts'
archive = '.SwiftPackages/artifacts'

check_case('modern artifact', binaries: [["#{tests}/#{modern}", '0.65.1', 'modern']], expected: 'modern')
check_case('legacy artifact', identity: 'swiftlint', version: '0.55.1', binaries: [["#{archive}/#{legacy}", '0.55.1', 'legacy']], expected: 'legacy')
check_case('active build precedence', binaries: [["#{active}/#{modern}", '0.65.1', 'active'], ["#{tests}/#{modern}", '0.65.1', 'cached']], fallback: '0.65.1', expected: 'active')
check_case('stale identity ignored', binaries: [["#{active}/#{legacy}", '0.55.1', 'stale'], ["#{archive}/#{modern}", '0.65.1', 'pinned']], expected: 'pinned')
check_case('stale version ignored', binaries: [["#{active}/#{modern}", '0.64.0', 'stale'], ["#{tests}/#{modern}", '0.65.1', 'pinned']], expected: 'pinned')
check_case('matching PATH fallback', binaries: [["#{tests}/#{modern}", '0.64.0', 'stale']], fallback: '0.65.1', expected: 'fallback')
check_case('mismatched PATH rejected', fallback: '0.64.0')
check_case('mismatched artifact rejected', binaries: [["#{tests}/#{modern}", '0.64.0', 'stale']])
check_case('wrong identity rejected', binaries: [["#{tests}/#{legacy}", '0.65.1', 'wrong-identity']])
check_case('missing binary rejected')
check_case('lint exit status preserved', binaries: [["#{tests}/#{modern}", '0.65.1', 'modern']], expected: 'modern', exit_status: 42)
puts '11 SwiftLint selection cases passed.'
