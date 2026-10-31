require 'fileutils'
require 'open3'
require 'tmpdir'

SOURCE = File.expand_path('../select-ci-xcode.sh', __dir__)

def check_case(name, required: '6.3', sdk: 'iphonesimulator', selected: 'Xcode-26.1.1.app', override: nil, toolchains: [], missing_sdks: {}, expected: nil, messages: [])
  Dir.mktmpdir('artemis-xcode-selection') do |directory|
    FileUtils.mkdir_p(File.join(directory, 'scripts'))
    FileUtils.cp(SOURCE, File.join(directory, 'scripts/select-ci-xcode.sh'))
    FileUtils.mkdir_p(File.join(directory, 'ArtemisKit'))
    File.write(File.join(directory, 'ArtemisKit/Package.swift'), "// swift-tools-version: #{required}\n")
    applications = File.join(directory, 'Applications with spaces')
    FileUtils.mkdir_p(applications)
    toolchains.each do |app, xcode, swift, build|
      developer = File.join(applications, app, 'Contents/Developer')
      FileUtils.mkdir_p(developer)
      File.write(File.join(developer, 'xcode-version'), "Xcode #{xcode}\nBuild version #{build || '17F6'}\n")
      File.write(File.join(developer, 'swift-version'), "Apple Swift version #{swift} (swiftlang-6.3.0.123 clang-1800.0.1)\nTarget: arm64-apple-macosx26.0\n") if swift
      { 'iphonesimulator' => 'iPhoneSimulator', 'iphoneos' => 'iPhoneOS' }.each do |sdk_name, platform|
        next if missing_sdks.fetch(app, []).include?(sdk_name)
        FileUtils.mkdir_p(File.join(developer, "Platforms/#{platform}.platform/Developer/SDKs/#{platform}.sdk"))
      end
    end
    tools = File.join(directory, 'tools')
    FileUtils.mkdir_p(tools)
    binaries = {
      'xcode-select' => <<~SH,
        [ "$*" = '--print-path' ] || exit 91
        [ -n "$ARTEMIS_TEST_SELECTED_XCODE" ] || exit 1
        printf '%s\\n' "$ARTEMIS_TEST_SELECTED_XCODE"
      SH
      'xcodebuild' => <<~SH,
        [ "$*" = '-version' ] || exit 92
        cat "$DEVELOPER_DIR/xcode-version"
      SH
      'xcrun' => <<~SH
        case "$*" in
          'swift --version') cat "$DEVELOPER_DIR/swift-version"; exit $? ;;
          '--sdk iphonesimulator --show-sdk-path') platform=iPhoneSimulator ;;
          '--sdk iphoneos --show-sdk-path') platform=iPhoneOS ;;
          *) exit 93 ;;
        esac
        sdk_path="$DEVELOPER_DIR/Platforms/$platform.platform/Developer/SDKs/$platform.sdk"
        if [ ! -d "$sdk_path" ]; then
          printf 'xcrun: error: SDK "%s" cannot be located\\n' "$2" >&2
          exit 1
        fi
        printf '%s\\n' "$sdk_path"
      SH
    }
    binaries.each do |binary, body|
      path = File.join(tools, binary)
      File.write(path, "#!/bin/sh\n#{body}")
      File.chmod(0755, path)
    end
    env_file = File.join(directory, 'github-env')
    File.write(env_file, "EXISTING=value\n")
    env = {
      'PATH' => "#{tools}:/usr/bin:/bin",
      'DEVELOPER_DIR' => override && File.join(applications, override, 'Contents/Developer'),
      'ARTEMIS_TEST_SELECTED_XCODE' => selected && File.join(applications, selected, 'Contents/Developer'),
      'ARTEMIS_XCODE_APPLICATIONS_DIRECTORY' => applications,
      'GITHUB_ENV' => env_file
    }
    arguments = ['bash', File.join(directory, 'scripts/select-ci-xcode.sh')]
    arguments << sdk if sdk
    output, error, status = Open3.capture3(env, *arguments, chdir: '/tmp')
    if expected
      raise "#{name}: selection failed: #{output}#{error}" unless status.success?
      developer = File.join(applications, expected, 'Contents/Developer')
      raise "#{name}: wrong job toolchain: #{File.read(env_file)}" unless File.read(env_file) == "EXISTING=value\nDEVELOPER_DIR=#{developer}\n"
      raise "#{name}: unexpected stderr: #{error}" unless error.empty?
    else
      raise "#{name}: accepted unavailable toolchain" if status.success?
      raise "#{name}: changed job environment on failure" unless File.read(env_file) == "EXISTING=value\n"
    end
    messages.each do |message|
      raise "#{name}: missing diagnostic #{message.inspect}: #{output}#{error}" unless "#{output}#{error}".include?(message)
    end
  end
end

check_case('keep compatible current Xcode', selected: 'Xcode-26.6.app',
           toolchains: [['Xcode-26.6.app', '26.6', '6.3'], ['Xcode-26.8.app', '26.8', '6.4']],
           expected: 'Xcode-26.6.app', messages: ['Xcode 26.6', 'Apple Swift version 6.3'])
check_case('replace old Xcode with newest compatible stable release',
           toolchains: [['Xcode-26.1.1.app', '26.1.1', '6.2.1'], ['Xcode-26.6.app', '26.6', '6.3'],
                        ['Xcode-26.10.app', '26.10', '6.4'], ['Xcode-27-beta.app', '27.0', '6.5']],
           expected: 'Xcode-26.10.app')
check_case('compare multi-digit Swift minor numerically', required: '6.10',
           toolchains: [['Xcode-26.1.1.app', '26.1.1', '6.3'], ['Xcode-27.app', '27.0', '6.10']],
           expected: 'Xcode-27.app')
check_case('honor compatible developer directory override', override: 'Xcode-26.6.app',
           toolchains: [['Xcode-26.1.1.app', '26.1.1', '6.2.1'], ['Xcode-26.6.app', '26.6', '6.3']],
           expected: 'Xcode-26.6.app')
check_case('reject old and prerelease fallbacks with inventory',
           toolchains: [['Xcode-26.1.1.app', '26.1.1', '6.2.1'], ['Xcode-26.5.app', '26.5', '6.2.3'],
                        ['Xcode-27-beta.app', '27.0', '6.4'], ['Xcode-27-RC.app', '27.0', '6.4'],
                        ['Xcode-27-Preview.app', '27.0', '6.4'], ['Xcode.app', '27.0', '6.4', '18A5211f']],
           messages: ['Swift 6.3', 'Xcode-26.1.1.app', '6.2.1', 'Xcode-26.5.app', '6.2.3', 'Xcode-27-beta.app', 'Xcode.app'])
check_case('find installed Xcode without a current selection', selected: nil,
           toolchains: [['Xcode-26.6.app', '26.6', '6.3']], expected: 'Xcode-26.6.app')
check_case('skip unusable toolchain', toolchains: [['Xcode-26.1.1.app', '26.1.1', nil], ['Xcode-26.6.app', '26.6', '6.3']],
           expected: 'Xcode-26.6.app')
check_case('report missing installed Xcode', selected: nil, messages: ['Swift 6.3', 'No installed Xcode'])
check_case('derive patch minimum from manifest', required: '6.3.1',
           toolchains: [['Xcode-26.1.1.app', '26.1.1', '6.3'], ['Xcode-26.6.app', '26.6', '6.3.1']],
           expected: 'Xcode-26.6.app')
check_case('reject invalid manifest tools version', required: 'invalid', messages: ['swift-tools-version'])
check_case('fall back when current Xcode lacks the simulator SDK', selected: 'Xcode-26.6.app',
           toolchains: [['Xcode-26.6.app', '26.6', '6.3'], ['Xcode-26.5.app', '26.5', '6.3']],
           missing_sdks: { 'Xcode-26.6.app' => ['iphonesimulator'] }, expected: 'Xcode-26.5.app')
check_case('reject installations lacking the simulator SDK', selected: 'Xcode-26.6.app',
           toolchains: [['Xcode-26.6.app', '26.6', '6.3']],
           missing_sdks: { 'Xcode-26.6.app' => ['iphonesimulator'] }, messages: ['Swift 6.3', 'iphonesimulator', 'cannot be located'])
check_case('release build needs only the device SDK', sdk: 'iphoneos', selected: 'Xcode-26.6.app',
           toolchains: [['Xcode-26.6.app', '26.6', '6.3']],
           missing_sdks: { 'Xcode-26.6.app' => ['iphonesimulator'] }, expected: 'Xcode-26.6.app')
check_case('fall back when current Xcode lacks the device SDK', sdk: 'iphoneos', selected: 'Xcode-26.6.app',
           toolchains: [['Xcode-26.6.app', '26.6', '6.3'], ['Xcode-26.5.app', '26.5', '6.3']],
           missing_sdks: { 'Xcode-26.6.app' => ['iphoneos'] }, expected: 'Xcode-26.5.app')
check_case('reject unsupported SDK argument', sdk: 'macosx', messages: ['iphonesimulator', 'iphoneos'])
check_case('require an explicit SDK argument', sdk: nil, messages: ['iphonesimulator', 'iphoneos'])
puts '16 Xcode selection cases passed.'
