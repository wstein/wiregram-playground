# frozen_string_literal: true

module SnapshotHelper
  def snapshot_dir(language = 'ucl')
    dir = File.expand_path("../snapshots/#{language}", __dir__)
    Dir.mkdir(File.dirname(dir)) unless Dir.exist?(File.dirname(dir))
    Dir.mkdir(dir) unless Dir.exist?(dir)
    dir
  end

  def snapshot_path(name, language = 'ucl')
    File.join(snapshot_dir(language), "#{name}.snap")
  end

  # Assert that content matches the snapshot named `name`.
  # If ENV['UPDATE_SNAPSHOTS'] is set truthy, write the snapshot instead.
  def assert_snapshot(name, content, language = 'ucl')
    path = snapshot_path(name, language)

    if ENV['UPDATE_SNAPSHOTS'] && !ENV['UPDATE_SNAPSHOTS'].empty?
      File.open(path, 'wb') { |f| f.write(content.to_s.encode('UTF-8')) }
      warn "[snapshot] wrote #{path}"
      return
    end

    raise "Snapshot missing: #{path}. Run tests with UPDATE_SNAPSHOTS=1 to create snapshots." unless File.exist?(path)

    expected = File.open(path, 'rb', &:read).force_encoding('UTF-8')
    # Compare after stripping trailing whitespace/newlines to avoid insignificant
    # differences in canonical emitters (matches user request to rstrip before compare)
    expect(content.to_s.encode('UTF-8').rstrip).to eq(expected.rstrip)
  end
end
