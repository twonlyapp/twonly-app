require "minitest/autorun"
require "fileutils"
require "tmpdir"

# Exercise the actual lanes with temporary projects and fake command results.
# No command is executed and successful cases stop before F-Droid deployment.
class LaneError < StandardError; end
class GithubFinished < StandardError; end

module UI
  def self.message(_message); end
  def self.important(_message); end
  def self.input(_message)
    "developer@example.com"
  end
  def self.user_error!(message)
    raise LaneError, message
  end
  def self.success(_message)
    raise GithubFinished
  end
end

class InternalLaneTest < Minitest::Test
  NOTES = "- New: English release notes\n- Fix: Photo sharing"

  def setup
    @root = Dir.mktmpdir("twonly-internal-test")
    FileUtils.mkdir_p(File.join(@root, "fastlane"))
    File.write(File.join(@root, "pubspec.yaml"), "version: 1.2.3+42\n")
    File.write(File.join(@root, "CHANGELOG.md"), "## 1.2.30\n\nWrong version\n\n## [1.2.3]\n\n#{NOTES}\n\n## 1.2.2\n\nOld notes\n")
    @bundle = File.join(@root, "build/app/outputs/bundle/release/app-release.aab")
    FileUtils.mkdir_p(File.dirname(@bundle))
    File.write(@bundle, "stale bundle")
    @lane = LaneHarness.new(@root)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def test_builds_from_project_root_before_uploading_the_fresh_bundle
    Dir.mktmpdir("twonly-internal-caller") do |caller_dir|
      Dir.chdir(caller_dir) do
        @lane.run_internal
        assert_equal File.realpath(caller_dir), Dir.pwd
      end
    end

    assert_equal [File.realpath(@root)], @lane.bundle_build_directories
    assert_equal [["flutter build appbundle --release"]], @lane.commands
    assert_equal 1, @lane.play_uploads.length
    assert_equal "fresh bundle", @lane.play_uploads.first.fetch(:bundle)
    assert_equal @bundle, @lane.play_uploads.first.fetch(:aab)
    assert_equal "internal", @lane.play_uploads.first.fetch(:track)
    assert_equal({ "en-US/changelogs/default.txt" => NOTES }, @lane.play_uploads.first.fetch(:changelogs))
    refute @lane.play_uploads.first.fetch(:skip_upload_changelogs)
    refute File.exist?(@lane.play_uploads.first.fetch(:metadata_path))
  end

  def test_missing_or_unmatched_changelog_uses_the_same_fallback_as_fdroid
    [nil, "## 1.2.30\n\nWrong version\n", "## 1.2.3\n\n"].each do |content|
      changelog = File.join(@root, "CHANGELOG.md")
      content ? File.write(changelog, content) : FileUtils.rm_f(changelog)
      @lane.run_internal
      assert_equal({ "en-US/changelogs/default.txt" => "Small bug fixes." }, @lane.play_uploads.last.fetch(:changelogs))
    end
  end

  def test_failed_upload_cleans_up_temporary_metadata
    @lane.fail_play_upload = true
    assert_raises(LaneError) { @lane.run_internal }
    refute File.exist?(@lane.play_uploads.last.fetch(:metadata_path))
  end

  def test_failed_build_never_uploads_an_existing_stale_bundle
    @lane.fail_build = true
    error = assert_raises(LaneError) { @lane.run_internal }
    assert_match(/Build failed/, error.message)
    assert_empty @lane.play_uploads
    assert_equal "stale bundle", File.read(@bundle)
  end
end

class TestflightLaneTest < Minitest::Test
  def setup
    @auth_environment = %w[PILOT_API_KEY_PATH APP_STORE_CONNECT_API_KEY_PATH PILOT_API_KEY APP_STORE_CONNECT_API_KEY PILOT_USERNAME FASTLANE_USER].to_h { |name| [name, ENV[name]] }
    @auth_environment.each_key { |name| ENV.delete(name) }
    @root = Dir.mktmpdir("twonly-testflight-test")
    FileUtils.mkdir_p(File.join(@root, "fastlane"))
    @ipa_dir = File.join(@root, "build/ios/ipa")
    FileUtils.mkdir_p(@ipa_dir)
    File.write(File.join(@ipa_dir, "old.ipa"), "stale IPA")
    @lane = LaneHarness.new(@root)
  end

  def teardown
    FileUtils.remove_entry(@root)
    @auth_environment.each { |name, value| ENV[name] = value }
  end

  def test_builds_from_project_root_and_uploads_only_the_new_ipa
    Dir.mktmpdir("twonly-testflight-caller") do |caller_dir|
      Dir.chdir(caller_dir) do
        @lane.run_beta
        assert_equal File.realpath(caller_dir), Dir.pwd
      end
    end
    assert_equal [File.realpath(@root)], @lane.ipa_build_directories
    assert_equal 1, @lane.commands.length
    assert_equal ["flutter", "build", "ipa", "--release", "--export-options-plist"], @lane.commands.first.first(5)
    assert_match(/<key>signingStyle<\/key><string>automatic<\/string>/, @lane.ipa_export_options)
    assert_match(/<key>teamID<\/key><string>CN332ZUGRP<\/string>/, @lane.ipa_export_options)
    refute_match(/<key>(signingCertificate|provisioningProfiles)<\/key>/, @lane.ipa_export_options)
    refute File.exist?(@lane.commands.first.last)
    assert_equal 1, @lane.testflight_uploads.length
    upload = @lane.testflight_uploads.first
    assert_equal File.join(@ipa_dir, "twonly.ipa"), upload.fetch(:ipa)
    assert_equal "fresh IPA", upload.fetch(:binary)
    assert_equal "eu.twonly", upload.fetch(:app_identifier)
    assert_equal "6743774441", upload.fetch(:apple_id)
    assert_equal "developer@example.com", upload.fetch(:username)
    assert upload.fetch(:skip_waiting_for_build_processing)
    refute File.exist?(File.join(@ipa_dir, "old.ipa"))
  end

  def test_failed_build_does_not_upload
    @lane.fail_build = true
    assert_raises(LaneError) { @lane.run_beta }
    assert_empty @lane.testflight_uploads
  end

  def test_successful_archive_without_an_export_does_not_upload_a_stale_ipa
    @lane.ipa_exports = []
    error = assert_raises(LaneError) { @lane.run_beta }
    assert_match(/found 0/, error.message)
    assert_empty @lane.testflight_uploads
  end

  def test_ambiguous_exports_do_not_upload
    @lane.ipa_exports = ["one.ipa", "two.ipa"]
    error = assert_raises(LaneError) { @lane.run_beta }
    assert_match(/found 2/, error.message)
    assert_empty @lane.testflight_uploads
  end

  def test_reexports_the_existing_archive_without_a_flutter_build
    archive = File.join(@root, "build/ios/archive/Runner.xcarchive")
    FileUtils.mkdir_p(archive)
    @lane.run_beta(skip_build: "true")
    command = @lane.commands.fetch(0)
    assert_equal 1, @lane.commands.length
    assert_equal ["xcodebuild", "-exportArchive"], command.first(2)
    assert_equal archive, command[command.index("-archivePath") + 1]
    assert_equal @ipa_dir, command[command.index("-exportPath") + 1]
    assert_includes command, "-allowProvisioningUpdates"
    assert_match(/<key>signingStyle<\/key><string>automatic<\/string>/, @lane.ipa_export_options)
    assert_equal 1, @lane.testflight_uploads.length
  end

  def test_missing_archive_stops_before_export_or_upload
    assert_raises(LaneError) { @lane.run_beta(skip_build: true) }
    assert_empty @lane.commands
    assert_empty @lane.testflight_uploads
  end

  def test_failed_reexport_stops_before_upload_and_cleans_up_options
    FileUtils.mkdir_p(File.join(@root, "build/ios/archive/Runner.xcarchive"))
    @lane.fail_build = true
    assert_raises(LaneError) { @lane.run_beta(skip_build: true) }
    assert_empty @lane.testflight_uploads
    command = @lane.commands.fetch(0)
    refute File.exist?(command[command.index("-exportOptionsPlist") + 1])
  end

  def test_passes_the_explicit_username_and_provider_to_the_uploader
    @lane.run_beta(username: "uploader@example.com", provider_public_id: "provider-public-id")
    assert_equal "uploader@example.com", @lane.testflight_uploads.last.fetch(:username)
    assert_equal "provider-public-id", @lane.testflight_uploads.last.fetch(:provider_public_id)
  end

  def test_uses_the_username_from_the_environment
    ENV['PILOT_USERNAME'] = "environment@example.com"
    @lane.run_beta
    assert_equal "environment@example.com", @lane.testflight_uploads.last.fetch(:username)
  end

  def test_api_key_authentication_does_not_receive_conflicting_username
    ENV['PILOT_API_KEY_PATH'] = "/outside-repository/api-key.json"
    ENV['PILOT_USERNAME'] = "unused@example.com"
    @lane.run_beta
    refute @lane.testflight_uploads.last.key?(:username)
  end
end

class PromoteLaneTest < Minitest::Test
  def setup
    @lane = LaneHarness.new("/unused-project")
  end

  def test_promotes_to_each_destination_without_building_or_reading_a_bundle
    { "closed" => "twonly-closed-tests", "open" => "beta", "production" => "production",
      "my-closed-track" => "my-closed-track" }.each do |input, destination|
      @lane.run_promote(track: input)
      upload = @lane.play_uploads.last
      assert_equal "internal", upload.fetch(:track)
      assert_equal destination, upload.fetch(:track_promote_to)
      assert_equal "completed", upload.fetch(:track_promote_release_status)
      assert upload.fetch(:skip_upload_apk)
      assert upload.fetch(:skip_upload_aab)
      assert upload.fetch(:skip_upload_changelogs)
      refute upload.key?(:aab)
      refute upload.key?(:apk)
    end
    assert_equal 4, @lane.play_uploads.length
    assert_empty @lane.commands
  end

  def test_defaults_to_all_destinations_and_always_promotes_from_internal
    [{}, { track: nil }, { track: "" }, { track: "  " }, { track: "all" }].each do |options|
      @lane.play_uploads.clear
      @lane.run_promote(options)

      assert_equal %w[twonly-closed-tests beta production], @lane.play_uploads.map { |upload| upload.fetch(:track_promote_to) }
      @lane.play_uploads.each do |upload|
        assert_equal "internal", upload.fetch(:track)
        assert_equal "completed", upload.fetch(:track_promote_release_status)
        %i[skip_upload_apk skip_upload_aab skip_upload_metadata skip_upload_changelogs skip_upload_images skip_upload_screenshots].each do |flag|
          assert upload.fetch(flag)
        end
      end
    end
    assert_empty @lane.commands
  end

  def test_rejects_internal_as_a_destination_before_contacting_google_play
    assert_raises(LaneError) { @lane.run_promote(track: "internal") }
    assert_empty @lane.play_uploads
  end
end

class LaneHarness
  EXPECTED_CERTIFICATE = "e3c44d568c67f932ac8c3390998ab95ee8ff2d7a073c24e3667793e6eacd770a"

  Status = Struct.new(:ok) do
    def success?
      ok
    end
  end

  attr_accessor :view_result, :upload_failures, :fail_build, :fail_play_upload
  attr_accessor :ipa_exports
  attr_reader :commands, :delays, :notes, :signature_results
  attr_reader :play_uploads, :bundle_build_directories
  attr_reader :testflight_uploads, :ipa_build_directories
  attr_reader :ipa_export_options

  def initialize(root)
    @commands = []
    @delays = []
    @lanes = {}
    @view_result = [true, "Existing release"]
    @upload_failures = 0
    @signature_results = {}
    @play_uploads = []
    @bundle_build_directories = []
    @testflight_uploads = []
    @ipa_build_directories = []
    @ipa_exports = ["twonly.ipa"]
    source = File.read(File.expand_path("../Fastfile", __dir__))
    instance_eval(source, File.join(root, "fastlane", "Fastfile"))
  end

  def default_platform(_platform); end
  def platform(_platform, &block)
    instance_eval(&block)
  end
  def desc(_description); end
  def lane(name, &block)
    @lanes[name] = block
  end
  def run(options = {})
    @lanes.fetch(:fdroid).call(options)
  end
  def run_internal
    @lanes.fetch(:internal).call
  end
  def run_promote(options = {})
    @lanes.fetch(:promote).call(options)
  end
  def run_beta(options = {})
    @lanes.fetch(:beta).call(options)
  end
  def upload_to_testflight(**options)
    @testflight_uploads << options.merge(binary: File.read(options.fetch(:ipa)))
  end
  def upload_to_play_store(**options)
    if options[:metadata_path]
      metadata_path = options[:metadata_path]
      changelogs = Dir.glob(File.join(metadata_path, "**", "*.txt")).to_h do |file|
        [file.delete_prefix("#{metadata_path}/"), File.read(file)]
      end
      options = options.merge(changelogs: changelogs)
    end
    @play_uploads << (options[:aab] ? options.merge(bundle: File.read(options[:aab])) : options)
    raise LaneError, "Play upload failed" if fail_play_upload
  end
  def sleep(seconds)
    @delays << seconds
  end

  def sh(*command, **_options, &block)
    @commands << command
    if command.first(3) == ["flutter", "build", "ipa"] || command.first(2) == ["xcodebuild", "-exportArchive"]
      @ipa_build_directories << Dir.pwd
      options_flag = command.first == "flutter" ? "--export-options-plist" : "-exportOptionsPlist"
      @ipa_export_options = File.read(command[command.index(options_flag) + 1])
      raise LaneError, "Build failed" if fail_build
      ipa_dir = File.join(Dir.pwd, "build/ios/ipa")
      FileUtils.mkdir_p(ipa_dir)
      ipa_exports.each { |name| File.write(File.join(ipa_dir, name), "fresh IPA") }
      return "Built"
    end
    if command == ["flutter build appbundle --release"]
      @bundle_build_directories << Dir.pwd
      raise LaneError, "Build failed" if fail_build
      path = File.join(Dir.pwd, "build/app/outputs/bundle/release/app-release.aab")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "fresh bundle")
      return "Built"
    end
    if command == ["flutter build apk --release --split-per-abi"]
      raise LaneError, "Build failed" if fail_build
      return "Built"
    end
    if File.basename(command.first) == "apksigner"
      result = signature_results.fetch(File.basename(command.last), [true, "Signer #1 certificate SHA-256 digest: #{EXPECTED_CERTIFICATE}\n"])
      return block.call(Status.new(result[0]), result[1], command.join(" "))
    end
    case command.first(3)
    when ["gh", "release", "view"]
      block.call(Status.new(view_result[0]), view_result[1], command.join(" "))
    when ["gh", "release", "create"]
      @notes = File.read(command[command.index("--notes-file") + 1])
      "Created"
    when ["gh", "release", "upload"]
      if upload_failures > 0
        @upload_failures -= 1
        raise LaneError, "Upload interrupted"
      end
      "Uploaded"
    else
      raise "Unexpected command: #{command.inspect}"
    end
  end
end

class FdroidLaneTest < Minitest::Test
  NOTES = "- Fix: multiline release notes\n- Literal `$(text)` and 'quotes'"

  def setup
    @root = Dir.mktmpdir("twonly-fdroid-test")
    FileUtils.mkdir_p(File.join(@root, "fastlane"))
    FileUtils.mkdir_p(File.join(@root, "android"))
    File.write(File.join(@root, "android/key.github.properties"), "github fixture")
    @apksigner = File.join(@root, "sdk/build-tools/36.0.0/apksigner")
    FileUtils.mkdir_p(File.dirname(@apksigner))
    File.write(@apksigner, "fixture apksigner")
    FileUtils.chmod(0755, @apksigner)
    File.write(File.join(@root, "android/local.properties"), "sdk.dir=#{File.join(@root, 'sdk')}\n")
    File.write(File.join(@root, "pubspec.yaml"), "version: 1.2.3+42\n")
    File.write(File.join(@root, "CHANGELOG.md"), "## 1.2.3\n\n#{NOTES}\n\n## 1.2.2\n\nOld notes\n")
    @apk_dir = File.join(@root, "build/app/outputs/flutter-apk")
    FileUtils.mkdir_p(@apk_dir)
    ["app-arm64-v8a-release.apk", "app-armeabi-v7a-release.apk"].each do |name|
      File.write(File.join(@apk_dir, name), "fixture APK")
    end
    @lane = LaneHarness.new(@root)
  end

  def teardown
    FileUtils.remove_entry(@root)
  end

  def commands(action)
    @lane.commands.select { |command| command.first(3) == ["gh", "release", action] }
  end

  def test_resume_existing_release_without_rebuilding
    assert_raises(GithubFinished) { @lane.run(skip_build: "true") }
    assert_empty commands("create")
    assert_equal 2, commands("upload").length
    assert commands("upload").all? { |command| command.last == "--clobber" }
    assert_equal [@apksigner, @apksigner, "gh", "gh", "gh"], @lane.commands.map(&:first)
    assert_equal Dir.glob(File.join(@apk_dir, "*.apk")), @lane.commands.first(2).map(&:last)
    assert @lane.commands.first(2).all? { |command| command[1..2] == ["verify", "--print-certs"] }
  end

  def test_missing_release_is_created_with_exact_notes_before_uploads
    @lane.view_result = [false, "release not found"]
    assert_raises(GithubFinished) { @lane.run(skip_build: true) }
    assert_equal 1, commands("create").length
    assert_equal NOTES, @lane.notes
    assert_equal "v1.2.3", commands("create").first[3]
    assert_equal ["view", "create", "upload", "upload"], @lane.commands.select { |command| command.first == "gh" }.map { |command| command[2] }
  end

  def test_transient_upload_errors_are_retried_per_asset
    @lane.upload_failures = 2
    assert_raises(GithubFinished) { @lane.run(skip_build: true) }
    uploads = commands("upload")
    assert_equal 4, uploads.length
    assert_equal 1, uploads.first(3).map { |command| command[4] }.uniq.length
    refute_equal uploads[2][4], uploads[3][4]
    assert_equal [5, 10], @lane.delays
  end

  def test_permanent_upload_failure_stops_before_fdroid
    @lane.upload_failures = 10
    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/Upload interrupted/, error.message)
    assert_equal 3, commands("upload").length
  end

  def test_authentication_and_network_errors_do_not_create_a_release
    @lane.view_result = [false, "HTTP 401: Bad credentials"]
    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/Could not check GitHub release/, error.message)
    assert_empty commands("create")
    assert_empty commands("upload")
  end

  def test_missing_apks_stop_before_github
    FileUtils.rm_f(Dir.glob(File.join(@apk_dir, "*.apk")))
    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/No release APKs found/, error.message)
    assert_empty @lane.commands
  end

  def test_wrong_certificate_on_any_apk_stops_all_publishing
    @lane.signature_results["app-armeabi-v7a-release.apk"] = [true, "Signer #1 certificate SHA-256 digest: 2cf34fd57fe6c938f94fa2e9249219bcef3af3f719190b0c0527adef5b7dc14b\n"]

    [{}, {skip_build: true}].each do |options|
      error = assert_raises(LaneError) { @lane.run(options) }
      assert_match(/Unexpected signing certificate for app-armeabi-v7a-release.apk/, error.message)
      assert_empty @lane.commands.select { |command| command.first == "gh" }
    end
  end

  def test_invalid_apk_signature_stops_publishing_even_if_certificate_matches
    @lane.signature_results["app-arm64-v8a-release.apk"] = [false, "Signer #1 certificate SHA-256 digest: #{LaneHarness::EXPECTED_CERTIFICATE}\nDOES NOT VERIFY"]
    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/APK signature verification failed/, error.message)
    assert_empty commands("view")
    assert_empty commands("upload")
  end

  def test_missing_certificate_digest_stops_publishing
    @lane.signature_results["app-arm64-v8a-release.apk"] = [true, "No certificate digest\n"]
    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/Unexpected signing certificate/, error.message)
    assert_empty commands("view")
  end

  def test_additional_signer_stops_publishing
    @lane.signature_results["app-arm64-v8a-release.apk"] = [true, "Signer #1 certificate SHA-256 digest: #{LaneHarness::EXPECTED_CERTIFICATE}\nSigner #2 certificate SHA-256 digest: #{'0' * 64}\n"]
    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/Unexpected signing certificate/, error.message)
    assert_empty commands("view")
  end

  def test_missing_apksigner_stops_publishing
    FileUtils.rm(@apksigner)
    previous_environment = %w[ANDROID_HOME ANDROID_SDK_ROOT PATH].to_h { |key| [key, ENV[key]] }
    previous_environment.each_key { |key| ENV[key] = "" }

    error = assert_raises(LaneError) { @lane.run(skip_build: true) }
    assert_match(/Could not find apksigner/, error.message)
    assert_empty @lane.commands
  ensure
    previous_environment&.each { |key, value| ENV[key] = value }
  end

  def test_normal_run_builds_and_restores_signing_configuration
    key = File.join(@root, "android/key.properties")
    File.write(key, "original fixture")
    File.write(File.join(@root, "android/key.github.properties"), "github fixture")
    assert_raises(GithubFinished) { @lane.run }
    assert_equal ["flutter build apk --release --split-per-abi"], @lane.commands.first
    assert_equal "original fixture", File.read(key)
    refute File.exist?(key + ".backup")
  end

  def test_missing_github_signing_configuration_stops_building_and_publishing
    FileUtils.rm(File.join(@root, "android/key.github.properties"))
    key = File.join(@root, "android/key.properties")
    File.write(key, "original fixture")

    [{}, {skip_build: true}].each do |options|
      error = assert_raises(LaneError) { @lane.run(options) }
      assert_match(/Missing android\/key.github.properties/, error.message)
      assert_empty @lane.commands
      assert_equal "original fixture", File.read(key)
      refute File.exist?(key + ".backup")
    end
  end

  def test_build_failure_restores_signing_configuration_and_stops_publishing
    key = File.join(@root, "android/key.properties")
    File.write(key, "original fixture")
    File.write(File.join(@root, "android/key.github.properties"), "github fixture")
    @lane.fail_build = true
    assert_raises(LaneError) { @lane.run }
    assert_equal "original fixture", File.read(key)
    assert_empty commands("view")
    assert_empty commands("upload")
  end
end
