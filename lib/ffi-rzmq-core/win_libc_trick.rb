module LoadedModules
	extend FFI::Library
	
	ffi_lib 'Kernel32'
	attach_function :GetCurrentProcess, [], :pointer
	attach_function :CloseHandle, [:pointer], :void
	attach_function :GetModuleHandleA, [:pointer], :pointer
	attach_function :GetModuleFileNameW, [:pointer, :pointer, :uint32], :uint32

	ffi_lib 'Psapi'
	attach_function :EnumProcessModules, [:pointer, :pointer, :uint32, :pointer], :int

	def self.get_module_path(module_name)
		process_handle = self.GetCurrentProcess

		modules = FFI::MemoryPointer.new(:pointer, 2048)
		needed = FFI::MemoryPointer.new(:uint32)

		result = self.EnumProcessModules(process_handle, modules, modules.size, needed)

		needed.read_uint.times do |i|
			module_handle = modules[i].read_pointer
			wpath = FFI::MemoryPointer.new :ushort, 512
			npath = FFI::MemoryPointer.new(:uint32)
			size = self.GetModuleFileNameW(module_handle, wpath, wpath.size)
			path = wpath.read_string(size*2).force_encoding('utf-16LE').encode('utf-8').strip
			if File.basename(path).downcase == module_name
				return path
			end
		end
		
		nil
	end
	
	def self.fix_ffi_libc
		libc_module_name = FFI::Library::LIBC
		if libc_module_path = get_module_path(libc_module_name)
			FFI::Library::LIBC.replace libc_module_path
		end
	end
	
	fix_ffi_libc
end