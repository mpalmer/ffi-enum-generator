require 'tempfile'
require 'open3'

module FFI
	module Library
		# Generate an `FFI::Enum` from C enum values
		#
		# @example A simple example for a days-of-the-week enum
		#
		#  # C:
		#  enum {
		#    SUNDAY,    # Automatically given the value '0'
		#    MONDAY,
		#    TUESDAY,
		#    WEDNESDAY,
		#    THURSDAY,
		#    FRIDAY,
		#    SATURDAY
		#  }
		#
		#  # Ruby:
		#  enum = FFI::EnumGenerator(:weekdays) do |gen|
		#    gen.symbol(:MONDAY)
		#    gen.symbol('TUESDAY')
		#    gen.symbol(:WEDNESDAY, :WED)  # this enum value's symbol will be :WED
		#    gen.symbol(:THURSDAY),
		#    gen.symbol(:FRIDAY)
		#  end
		#
		#  enum.class       # => FFI::Enum
		#  enum[:MONDAY]    # => 1
		#  enum[:TUESDAY]   # => 2
		#  enum[:WED]       # => 3
		#  enum[:WEDNESDAY] # => nil
		#  enum[:ohai]      # => nil
		#
		# @note Specifying a symbol that isn't known, will cause assplosions.
		#   Specifying a symbol that isn't an enum value may work, but is not
		#   guaranteed to continue to work.
		#
		# @param name [#to_s] The name of the enum to create.
		#
		# @return [FFI::Enum] The newly-created enum.
		#
		# @yieldparam gen [FFI::EnumGenerator] The generator is passed to the
		#   block, so you can use {FFI::EnumGenerator#include} and
		#   {FFI::EnumGenerator#symbol} to define the enum before it is
		#   generated.
		#
		def generate_enum(name, &blk)
			enum name, ::FFI::EnumGenerator.new(&blk).generate
		end
	end

	class EnumGenerator
		# Creates a new enum generator.
		#
		# You probably don't want to instantiate one of these directly.  Take
		# a look at {FFI::Library.generate_enum} instead.
		#
		def initialize
			@includes = ["stdio.h"]
			@enum_symbols = {}

			yield self if block_given?
		end

		# Add a symbolic value to the enum.
		#
		# @param name [#to_s] The name of the enum value to lookup.
		#
		# @param ruby_name [#to_sym] The name that the enum value will have
		#   inside the Ruby enum.  This is useful to remove namespacing
		#   prefixes that are unnecessary in Ruby, or to make the symbols more
		#   pleasing to the eye (camel-casing, for instance).
		#
		def symbol(name, ruby_name = nil)
			ruby_name ||= name
			@enum_symbols[name] = ruby_name
		end

		# Add additional C include file(s) to use to lookup the enum values.
		#
		# You should use this method to add the `.h` files needed to fully
		# define the enum(s) you wish to extract values from.
		#
		# @param i [List<String>, Array<String>] The additional file(s) to
		#   include.
		#
		# @return [Array<String>] The complete array of included files.
		#
		def include(*i)
			@includes += i.flatten
		end

		# Generate an array of enum symbols and values.
		#
		# You probably don't ever want to call this yourself.  We use it to
		# feed the enum creation code.
		#
		# @return [Array] Alternating symbols and values for the new enum.
		#
		def generate
			binary = File.join Dir.tmpdir, "rb_ffi_enum_gen_bin_#{Process.pid}"

			Tempfile.open("#{@name}.enum_generator") do |f|
				@includes.each do |inc|
					f.puts "#include <#{inc}>"
				end
				f.puts "\nint main(void)\n{"

				@enum_symbols.each do |name, ruby_name|
					f.puts <<-EOF.gsub(/^\t{6}/, '')
						printf("#{ruby_name} %d\\n", #{name});
					EOF
				end

				f.puts "\n\treturn 0;\n}"
				f.flush

				output = `gcc -x c -Wall -Werror #{f.path} -o #{binary} 2>&1`

				unless $?.success? then
					output = output.split("\n").map { |l| "\t#{l}" }.join "\n"
					raise "Compilation error generating constants #{@prefix}:\n#{output}"
				end
			end

			output = `#{binary}`
			File.unlink(binary + (FFI::Platform.windows? ? ".exe" : ""))
			output.split("\n").inject([]) do |a, l|
				l =~ /^(\S+)\s(.*)$/
				a += [$1.to_sym, Integer($2)]
			end
		end
	end

	class Enum
		# Set constants on the given module for each symbol in this enum
		#
		# This will blow up if a constant of the same name is already defined
		# on `mod`, so you probably don't want to do that.
		#
		# @param mod [Module] The module upon which the constants will be set.
		#
		def set_consts(mod)
			symbols.each { |s| mod.const_set(s, self[s]) }
		end
	end
end
