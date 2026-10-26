require 'bundler/setup'
require 'fileutils'
require 'open3'
require 'tmpdir'
require 'rbconfig'

# Run each lane in a separate process so fixture warnings stay out of CI output
# and signing/action stubs cannot affect other cases.
if ARGV.first == '--run-fixture'
  require 'fastlane'
  require 'fastlane/helper/sh_helper'
  require 'fastlane/actions/build_app'
  require 'fastlane/actions/sync_code_signing'
  require 'gym'

  ENV['GEM_PATH'] ||= Gem.path.join(File::PATH_SEPARATOR)
  ENV['GEM_HOME'] ||= File.join(Dir.tmpdir, 'artemis-fixture-gem-home')
  ENV['_ORIGINAL_GEM_PATH'] ||= 'artemis-fixture-original-gem-path'

  CredentialsManager::AppfileConfig.define_singleton_method(:try_fetch_value) do |key|
    { app_identifier: 'de.tum.cit.ase.artemis', team_id: 'FAKETEAM01' }.fetch(key)
  end

  # Replace only Gym's native build boundary. BuildAppAction itself still
  # validates/merges options and returns the archive path used by the lane.
  Gym::Manager.class_eval do
    def work(config)
      raise 'Gym packaging was not disabled' unless config[:skip_package_ipa]
      Gym.instance_variable_set(:@config, config)
      Gym.cache = {}
      archive = File.expand_path('fixture archive with spaces.xcarchive')
      config[:archive_path] = archive
      FileUtils.mkdir_p([archive, config[:buildlog_path]])
      File.write(File.join(archive, 'Info.plist'), 'fixture archive')
      File.write(File.join(config[:buildlog_path], 'archive.log'), "** ARCHIVE SUCCEEDED **\n")
      archive
    end
  end

  class ArchiveExportLane
    UI = FastlaneCore::UI

    def initialize(path)
      @lanes = {}
      instance_eval(File.read(path), path)
    end

    def default_platform(*) = nil
    def desc(*) = nil
    def platform(_name, &block) = instance_eval(&block)
    def lane(name, &block) = @lanes[name] = block
    def setup_ci(*) = nil
    def update_code_signing_settings(*) = nil
    def increment_build_number(*) = nil
    def api_key = { fixture: true }

    def match(options)
      Fastlane::Actions::SyncCodeSigningAction.define_profile_type(type: options.fetch(:type))
      Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::MATCH_PROVISIONING_PROFILE_MAPPING] =
        options.fetch(:app_identifier).to_h { |identifier| [identifier, "match AppStore #{identifier}"] }
    end

    def build_app(**options)
      config = FastlaneCore::Configuration.create(Gym::Options.available_options, options)
      archive = Fastlane::Actions::BuildAppAction.run(config)
      shared_archive = Fastlane::Actions.lane_context[Fastlane::Actions::SharedValues::XCODEBUILD_ARCHIVE]
      raise 'BuildAppAction did not return the archive' unless archive == shared_archive && File.directory?(archive)
      archive
    end

    def sh(*arguments, &block)
      Fastlane::Actions.sh_no_action(*arguments, log: true, &block)
    end

    def run_build = instance_exec(&@lanes.fetch(:build))
  end

  ArchiveExportLane.new(ARGV.fetch(1)).run_build
  exit
end

repository_root = File.expand_path('../..', __dir__)
cases = {
  'success' => nil,
  'warning_stdout' => 'Build emitted 1 warning diagnostics.',
  'warning_stderr' => 'Build emitted 1 warning diagnostics.',
  'deprecation' => 'Build emitted 1 warning diagnostics.',
  'failure' => 'Archive export failed (exit 42).',
  'missing_ipa' => 'Expected one exported IPA, found 0.',
  'multiple_ipas' => 'Expected one exported IPA, found 2.'
}

Dir.mktmpdir('artemis-archive-export') do |root|
  cases.each do |mode, expected_error|
    directory = File.join(root, mode, 'workspace with spaces')
    %w[fastlane scripts tools build].each { |path| FileUtils.mkdir_p(File.join(directory, path)) }
    FileUtils.cp(File.join(repository_root, 'fastlane/Fastfile'), File.join(directory, 'fastlane/Fastfile'))
    FileUtils.cp(File.join(repository_root, 'scripts/check-build-warnings.rb'), File.join(directory, 'scripts/check-build-warnings.rb'))
    File.write(File.join(directory, 'build/App.ipa'), 'stale IPA')
    tools = File.join(directory, 'tools')
    FileUtils.ln_s(RbConfig.ruby, File.join(tools, 'ruby'))
    exporter = File.join(tools, 'xcrun')
    File.write(exporter, <<~'EXPORTER')
      #!/usr/bin/env ruby
      contaminated = %w[RUBYLIB RUBYOPT BUNDLE_BIN_PATH _ORIGINAL_GEM_PATH BUNDLE_GEMFILE GEM_HOME GEM_PATH].select { |name| ENV.key?(name) }
      abort "Ruby environment leaked into exporter: #{contaminated.join(', ')}" unless contaminated.empty?
      ENV['BUNDLE_GEMFILE'] = ENV.fetch('ARTEMIS_FIXTURE_GEMFILE')
      require 'bundler/setup'
      require 'plist'
      require 'fileutils'
      abort 'Unexpected xcrun tool' unless ARGV.shift == 'xcodebuild'
      abort 'Expected archive export' unless ARGV.shift == '-exportArchive'
      args = Hash[ARGV.each_slice(2).to_a]
      abort 'Wrong exporter arguments' unless args.keys.sort == %w[-archivePath -exportOptionsPlist -exportPath].sort
      abort 'Archive path lost spaces' unless File.file?(File.join(args.fetch('-archivePath'), 'Info.plist'))
      plist = Plist.parse_xml(args.fetch('-exportOptionsPlist'))
      abort 'Deprecated export method' unless plist.fetch('method') == 'app-store-connect'
      abort 'Export destination could upload' unless plist.fetch('destination') == 'export'
      abort 'Manual signing lost' unless plist.fetch('signingStyle') == 'manual'
      abort 'Wrong team' unless plist.fetch('teamID') == 'FAKETEAM01'
      profiles = {
        'de.tum.cit.ase.artemis' => 'match AppStore de.tum.cit.ase.artemis',
        'de.tum.cit.ase.artemis.ArtemisNotificationExtension' => 'match AppStore de.tum.cit.ase.artemis.ArtemisNotificationExtension',
        'de.tum.cit.ase.artemis.ArtemisWidgetExtension' => 'match AppStore de.tum.cit.ase.artemis.ArtemisWidgetExtension'
      }
      abort 'Profile mappings changed' unless plist.fetch('provisioningProfiles') == profiles
      puts 'exporter stdout diagnostic'
      warn 'exporter stderr diagnostic'
      mode = ENV.fetch('ARTEMIS_EXPORT_MODE')
      if mode == 'failure'
        warn 'error: fixture exporter failure'
        exit 42
      end
      puts 'warning: fixture export warning on stdout' if mode == 'warning_stdout'
      warn 'warning: fixture export warning on stderr' if mode == 'warning_stderr'
      puts 'Command line name app-store is deprecated. Use app-store-connect instead.' if mode == 'deprecation'
      FileUtils.mkdir_p(args.fetch('-exportPath'))
      File.write(File.join(args.fetch('-exportPath'), 'Artemis.ipa'), 'fresh IPA') unless mode == 'missing_ipa'
      File.write(File.join(args.fetch('-exportPath'), 'Unexpected.ipa'), 'unexpected IPA') if mode == 'multiple_ipas'
    EXPORTER
    File.chmod(0755, exporter)
    env = {
      'PATH' => "#{tools}:#{ENV.fetch('PATH')}",
      'BUNDLE_GEMFILE' => File.join(repository_root, 'Gemfile'),
      'ARTEMIS_FIXTURE_GEMFILE' => File.join(repository_root, 'Gemfile'),
      'ARTEMIS_EXPORT_MODE' => mode
    }
    output, error, status = Open3.capture3(env, RbConfig.ruby, File.expand_path(__FILE__), '--run-fixture',
                                         File.join(directory, 'fastlane/Fastfile'), chdir: directory)
    ipa = File.join(directory, 'build/App.ipa')
    if expected_error
      raise "#{mode}: failure was accepted" if status.success?
      raise "#{mode}: unrelated failure: #{output}#{error}" unless "#{output}#{error}".include?(expected_error)
      raise "#{mode}: stale or failed IPA artifact retained" if File.exist?(ipa)
    else
      raise "#{mode}: export failed: #{output}#{error}" unless status.success?
      raise 'Missing or stale final IPA' unless File.read(ipa) == 'fresh IPA'
    end
    log = File.read(File.join(directory, 'build/app-logs/export.log'))
    raise "#{mode}: stdout missing from export log" unless log.include?('exporter stdout diagnostic')
    raise "#{mode}: stderr missing from export log" unless log.include?('exporter stderr diagnostic')
  end
end
puts '7 archive export cases passed.'
