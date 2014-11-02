Enums in C are weird.  They like `#define` constant, with delusions of being
a "real type".  Behind the scenes, however, they're just a number.  And
there's no guarantee that the number won't change.

FFI comes with a neat "constant generator", that will avoid the problem of
constants changing by getting the constant values out of the source code, at
runtime.  This is great, but enums have exactly the same problem as
`#define`d constants, and the constant generator doesn't work on enums.  So,
I adapted the `FFI::ConstGenerator` code into this handy-dandy enum
generator.  As a bonus, since you often want to be able to refer to enum
values as constants, you can turn all the symbols in an enum into constants
on a module.


# Installation

It's a gem:

    gem install ffi-constant-generator

If you're the sturdy type that likes to run from git:

    rake build; gem install pkg/ffi-enum-generator-<whatever>.gem

Or, if you've eschewed the convenience of Rubygems, then you presumably know
what to do already.


# Usage

To generate an enum, use the `generate_enum` method in your
`FFI::Library`-using class:

    require 'ffi/enum_generator'

    class MyFFI
      extend ::FFI::Library
      ffi_lib "foo.so"

      generate_enum :foo_bar_opts do |eg|
        # The enum is defined in here, so we need to know that so we can
        # get the values
        eg.include "foo/bar.h"

        eg.symbol("FOO_BAR_FROB",   "FROB")
        eg.symbol("FOO_BAR_BAZ",    "BAZ")
        eg.symbol("FOO_BAR_WOMBAT", "WOMBAT")
      end
    end

This will create an enum named `:foo_bar_opts`, with the symbols `:FROB`,
`:BAZ`, and `:WOMBAT` with values equal to the C enum's values for
`FOO_BAR_FROB`, `FOO_BAR_BAZ`, and `FOO_BAR_WOMBAT`, respectively.  If you
leave off the second argument to `eg.symbol`, the symbols in your enum will
be the same as the original names, but since anyone sane namespaces their
enum values with prefixes, it's rare that you'll want to do that.

Once your enum is generated, you can use it in exactly the same way as you
would any other typed enum.  You can refer to it in your `attach_function`
calls:

    class MyFFI
      attach_function :frobber,
                      [:pointer, :foo_bar_opts],
                      :int
    end

Or retrieve it at will using `MyFFI.enum_type`:

    puts "foo_bar_opts[:wombat] is #{MyFFI.enum_type(:foo_bar_opts)[:WOMBAT]}"

Since going through all that rigamarole is a lot of typing, and not very
Rubyesque, you can set all the enum symbols up as constants on a module,
like so:

    module FooBarOpts; end

    MyFFI.enum_type(:foo_bar_opts).set_consts(FooBarOpts)

    puts "foo_bar_opts[:wombat] is #{FooBarOpts::WOMBAT}"

Neat, huh?


# Contributing

Bug reports should be sent to the [Github issue
tracker](https://github.com/mpalmer/ffi-enum-generator/issues), or
[e-mailed](mailto:theshed+ffi-enum-generator@hezmatt.org).  Patches can be
sent as a Github pull request, or
[e-mailed](mailto:theshed+ffi-enum-generator@hezmatt.org).
