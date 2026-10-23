require "minitest/autorun"
require "fileutils"
require "tmpdir"

# Exercise the actual lane with a temporary project and fake command results.
# No command is executed and successful cases stop before F-Droid deployment.
class LaneError < StandardError; end
class GithubFinished < StandardError; end

module UI
  def self.message(_message); end
  def self.important(_message); end
  def self.user_error!(message)
    raise LaneError, message
  end
  def self.success(_message)
    raise GithubFinished
  end
end

class LaneHarness
  EXPECTED_CERTIFICATE = "e3c44d568c67f932ac8c3390998ab95ee8ff2d7a073c24e3667793e6eacd770a"

  Status = Struct.new(:ok) do
    def success?
      ok
    end
  end

  attr_accessor :view_result, :upload_failures, :fail_build
  attr_reader :commands, :delays, :notes, :signature_results

  def initialize(root)
    @commands = []
    @delays = []
    @lanes = {}
    @view_result = [true, "Existing release"]
    @upload_failures = 0
    @signature_results = {}
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
  def sleep(seconds)
    @delays << seconds
  end

  def sh(*command, **_options, &block)
    @commands << command
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
