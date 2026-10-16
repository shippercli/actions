#!/usr/bin/env ruby

require 'fileutils'
require 'minitest/autorun'
require 'open3'
require 'tmpdir'
require 'yaml'

class CommandArgumentsTest < Minitest::Test
  def setup
    @directory = Dir.mktmpdir('shipper-action-arguments-')
    @capture = File.join(@directory, 'arguments')
    @output = File.join(@directory, 'output')
    bin = File.join(@directory, 'vendor', 'bin')
    FileUtils.mkdir_p(bin)
    File.write(File.join(bin, 'shipper'), <<~BASH)
      #!/usr/bin/env bash
      printf '%s\\0' "$@" > "$CAPTURE"
      exit "${STUB_EXIT:-0}"
    BASH
    File.chmod(0755, File.join(bin, 'shipper'))
    action = YAML.load_file(File.expand_path('../.github/actions/shipper/action.yml', __dir__))
    step = action.fetch('runs').fetch('steps').find { |entry| entry['id'] == 'run-shipper' }
    @script = File.join(@directory, 'run.sh')
    File.write(@script, step.fetch('run'))
  end

  def teardown
    FileUtils.remove_entry(@directory)
  end

  def run_action(inputs = {})
    env = {
      'COMMAND' => 'apply', 'PROJECT' => '', 'PROFILE' => '', 'FORCE' => 'false',
      'RELEASE' => '', 'LINES' => '', 'SHIPPER_HOME' => @directory,
      'GITHUB_OUTPUT' => @output, 'CAPTURE' => @capture, 'STUB_EXIT' => '0'
    }.merge(inputs)
    stdout, stderr, status = Open3.capture3(env, 'bash', @script)
    args = File.exist?(@capture) ? File.binread(@capture).split("\0") : nil
    [args, status.exitstatus, stdout, stderr]
  end

  def test_project_cannot_enable_force
    args, status = run_action('PROJECT' => '--force')
    assert_equal 0, status
    assert_equal ['apply', '--', '--force'], args
  end

  def test_explicit_options_precede_literal_project
    args, status = run_action('PROJECT' => 'my app', 'PROFILE' => 'production', 'FORCE' => 'true')
    assert_equal 0, status
    assert_equal ['apply', '--profile=production', '--force', '--', 'my app'], args
  end

  def test_shell_syntax_and_newlines_remain_one_argument_and_are_not_logged
    marker = File.join(@directory, 'must-not-exist')
    project = "$(touch #{marker})\n::error::untrusted"
    args, status, stdout = run_action('PROJECT' => project)
    assert_equal 0, status
    assert_equal ['apply', '--', project], args
    refute File.exist?(marker)
    refute_includes stdout, '::error::'
  end

  def test_optional_command_arguments_and_exit_code_are_preserved
    args, status = run_action('COMMAND' => 'rollback', 'PROJECT' => 'api', 'RELEASE' => 'release 1', 'STUB_EXIT' => '23')
    assert_equal 23, status
    assert_equal ['rollback', '--release=release 1', '--', 'api'], args
    assert_equal "exit-code=23\n", File.read(@output)
  end

  def test_command_without_project
    args, status = run_action('COMMAND' => 'logs', 'LINES' => '25')
    assert_equal 0, status
    assert_equal ['logs', '--lines=25'], args
  end

  def test_unsupported_command_never_executes
    args, status = run_action('COMMAND' => 'apply; touch forbidden')
    assert_equal 2, status
    assert_nil args
  end
end
