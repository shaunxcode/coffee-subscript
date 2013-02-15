# DRAFT

----

CoffeeSubscript is like
[CoffeeScript](http://jashkenas.github.com/coffee-script/) but enabling you to
embed DSL fragments in your source code.  For instance

    console.info «(2=+⌿0=A∘.∣A)/A←⍳100»

computes the first few primes using an APL one-liner.  Guillemets (`«»`) mark
an embedded piece of a DSL.

Alternatively, you can use the squiggly arrow (`~>`) to create a function whose
body consists of DSL code:

    countDown = ~>
      a ← ⍳ 10
      1 + ⌽ a
    console.info countDown() # prints [10, 9, 8, 7, 6, 5, 4, 3, 2, 1]

# Installation and usage

    npm install coffee-subscript -g

This will provide the `coffee-subscript` command which mimics the same options
as the `coffee` command.  For instance:

    coffee-subscript -c path/to/script.coffee

would compile a script peppered with DSL chunks.

# How it works

CoffeeSubscript is a preprocessor.  Actual compilation of CoffeeScript code is
handled by the CoffeeScript compiler itself.  DSL fragments are, of course,
compiled by their respective compilers.

# For DSL developers

We need your module to be usable like this:

    var jsCode = require('yourModule').compile(dslCode, opts);

The `jsCode` you return will be wrapped in

* `(function () {...})()` in the case of `«»` syntax

* `(function () {...})` in the case of `~>` syntax

The `opts` we supply are:

* `embedded`: always `true`

* `kind`: either `"expression"` (for `«»` syntax) or `"function"` (for `~>`
  syntax).  Note that in both cases you should have a `return` statement in
  your output.

* `line`, `column`: the position in the original source where DSL code
  begins

* `vars`: a list of dictionaries describing variables in enclosing scopes,
  e.g. for this piece of code

        a = 123
        b = (c) ->
          d = 'bar'
          «...»

  you will get

        [{"name": "a"}, {"name": "b"}, {"name": "c"}, {"name": "d"}]
