module Warp
  module Input
    # Why padding may be required for SIMD
    #
    # Some SIMD helpers load 16 bytes at a time (e.g. ld1 {v0.16b}, [ptr]).
    # The lexer avoids overreads by only invoking those helpers on full blocks.
    # If you plan to call SIMD helpers on arbitrary buffers without bounds
    # checks, pad the input with 16 zero bytes to keep the loads safe.
    #
    # We provide utility helpers below that allocate a padded buffer, read a
    # file into it, and zero the trailing bytes. Callers are responsible for
    # freeing the returned buffer with `free_padded_buffer`.
    {% if flag?(:aarch64) %}
    lib LibC_Read
      fun malloc(size : UInt64) : Pointer(Void)
      fun free(ptr : Pointer(Void)) : Nil
      fun memcpy(dest : Pointer(Void), src : Pointer(Void), n : UInt64) : Pointer(Void)
      fun memset(dest : Pointer(Void), c : Int32, n : UInt64) : Pointer(Void)
    end

    # read_file_padded(path) -> (ptr, len)
    #
    # Allocates a buffer of file_size + 16, reads the file content into it and
    # zeroes the trailing 16 bytes. Returns a pointer to the buffer (Pointer(UInt8))
    # and the original file length as Int32. On error the function returns
    # Pointer(UInt8).null and length 0.
    def self.read_file_padded(path : String) : Tuple(Pointer(UInt8), Int32)
      o_rdonly = 0
      seek_set = 0
      seek_end = 2

      fd = LibC.open(path.to_unsafe, o_rdonly, 0)
      if fd < 0
        return {Pointer(UInt8).null, 0}
      end

      size = LibC.lseek(fd, 0, seek_end)
      if size < 0
        LibC.close(fd)
        return {Pointer(UInt8).null, 0}
      end
      LibC.lseek(fd, 0, seek_set)

      total = size.to_u64 + 16_u64
      allocated = LibC_Read.malloc(total)
      if allocated.null?
        LibC.close(fd)
        return {Pointer(UInt8).null, 0}
      end

      read_total = 0_i64
      while read_total < size
        r = LibC.read(fd, allocated + read_total, (size - read_total).to_u64)
        if r <= 0
          LibC_Read.free(allocated)
          LibC.close(fd)
          return {Pointer(UInt8).null, 0}
        end
        read_total += r
      end

      LibC_Read.memset(allocated + size, 0, 16_u64)
      LibC.close(fd)

      {allocated.as(Pointer(UInt8)), size.to_i}
    end

    # free_padded_buffer(ptr)
    #
    # Free a buffer previously returned by `read_file_padded`.
    def self.free_padded_buffer(ptr : Pointer(UInt8))
      return if ptr.null?
      LibC_Read.free(ptr.as(Pointer(Void)))
    end

    # read_file_padded_bytes(path) -> Bytes
    #
    # Convenience wrapper that returns a GC-managed `Bytes` slice backed by an
    # `Array(UInt8)` containing the file contents plus 16 zero bytes. This is
    # the recommended high-level API in Crystal code since it avoids manual
    # malloc/free and is safe to pass to SIMD-backed functions.
    def self.read_file_padded_bytes(path : String) : Bytes
      # Try to read directly into a Crystal-managed Array(UInt8) to avoid
      # an extra copy. This is done using low-level libc syscalls to get the
      # file size and perform direct reads into the array's memory.
      begin
        o_rdonly = 0
        seek_end = 2
        seek_set = 0

        fd = LibC.open(path.to_unsafe, o_rdonly, 0)
        return Bytes.new(0) if fd < 0

        size = LibC.lseek(fd, 0, seek_end)
        if size < 0
          LibC.close(fd)
          return Bytes.new(0)
        end
        LibC.lseek(fd, 0, seek_set)

        buf = Bytes.new(size.to_i + 16)
        read_total = 0_i64
        while read_total < size
          r = LibC.read(fd, buf.to_unsafe + read_total, (size - read_total).to_u64)
          if r <= 0
            LibC.close(fd)
            return Bytes.new(0)
          end
          read_total += r
        end

        LibC.close(fd)
        # trailing bytes are zero-initialized by Bytes.new
        buf
      rescue ex
        Bytes.new(0)
      end
    end
    {% end %}
  end
end
