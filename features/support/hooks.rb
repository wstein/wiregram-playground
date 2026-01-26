# frozen_string_literal: true

After do
  next unless defined?(@tempfile) && @tempfile

  @tempfile.close
  @tempfile.unlink
  @tempfile = nil
  @tempfile_path = nil
end
