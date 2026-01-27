module SnapshotHelper
  extend self
  def snapshot_dir(language = "ucl")
    dir = File.expand_path("../../../../features/snapshots/#{language}", __DIR__)
    Dir.mkdir_p(dir)
    dir
  end

  def snapshot_path(name, language = "ucl")
    File.join(snapshot_dir(language), "#{name}.snap")
  end

  # Assert that content matches the snapshot named `name`.
  # If ENV["UPDATE_SNAPSHOTS"] is set truthy, write the snapshot instead.
  def assert_snapshot(name, content, language = "ucl")
    path = snapshot_path(name, language)
    update = ENV["UPDATE_SNAPSHOTS"]?

    if update && !update.empty?
      File.write(path, content.to_s)
      STDERR.puts "[snapshot] wrote #{path}"
      return
    end

    unless File.exists?(path)
      raise "Snapshot missing: #{path}. Run tests with UPDATE_SNAPSHOTS=1 to create snapshots."
    end

    expected = File.read(path)
    expect(content.to_s.rstrip).to eq(expected.rstrip)
  end
end
