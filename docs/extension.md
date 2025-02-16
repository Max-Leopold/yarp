# Extension

Part of this parser project is a native extension that provides a Ruby API that wraps calls to the C API. This allows you to invoke parsing from Ruby code. It also provides a Ruby API for accessing the syntax tree.

For the most part, the API for accessing the tree mirrors that found in the [Syntax Tree](https://github.com/ruby-syntax-tree/syntax_tree) project. This means:

* Walking the tree involves creating a visitor and passing it to the `#accept` method on any node in the tree
* Nodes in the tree respond to named methods for accessing their children as well as `#child_nodes`
* Nodes respond to the pattern matching interfaces `#deconstruct` and `#deconstruct_keys`

Every entry in `config.yml` will generate a Ruby class as well as the code that builds the nodes themselves. Creating a syntax tree involves calling one of the class methods on the `YARP` module. The full API is documented below.

## API

* `YARP.dump(source)` - parse the syntax tree corresponding to the given source string and serialize it to a string
* `YARP.dump_file(filepath)` - parse the syntax tree corresponding to the given source file and serialize it to a string
* `YARP.lex(source)` - parse the tokens corresponding to the given source string and return them as an array within a parse result
* `YARP.lex_file(filepath)` - parse the tokens corresponding to the given source file and return them as an array within a parse result
* `YARP.parse(source)` - parse the syntax tree corresponding to the given source string and return it within a parse result
* `YARP.parse_file(filepath)` - parse the syntax tree corresponding to the given source file and return it within a parse result
