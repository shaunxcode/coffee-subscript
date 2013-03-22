# This is a pre-processor for CoffeeScript.  Compiles DSL fragments to
# JavaScript literals surrounded with backquotes.

CoffeeScript = require 'coffee-script'

exports.preprocess = (mixedCode, opts = {}) ->

  # # Step 1: DSL fragments -> placeholders

  # Collect DSL fragments and replace them with placeholders of the form
  # `` `@123` ``, where `123` is the fragment id.
  fragments = []

  # Collect fragments delimited with `«»`
  mixedCode = mixedCode.replace /«([^»]*)»/g, (_, dslCode) ->
    fragments.push kind: 'expression', dslCode: dslCode
    padding = dslCode.replace /[^\n]/g, '' # pad with newlines to preserve line numbering
    "`@#{fragments.length - 1}#{padding}`"

  # Collect bodies of inline squiggly arrow funtions (`~>`)
  lines = mixedCode.split '\n'
  i = 0
  while i < lines.length
    if /\(\s*~>.*\)/.test lines[i]
      while (squiggleStart = lines[i].indexOf "~>") isnt -1
        startPos = squiggleStart
        while (startPos > 0)
            startPos--
            if lines[i][startPos] is "("
                break

        max = lines[i].length - 1
        escape = false
        inQuote = false
        parens = 1
        stopPos = squiggleStart + 1
        while parens
          stopPos++
          if stopPos > max 
            throw "Did not match paren"

          char = lines[i][stopPos]
          if inQuote
            if escape
              escape = false
            else if char is "\\"
              escape = true
            else if char is '"'
              inQuote = false
          else if char is '"'
            inQuote = true
          else if char is "("
            parens++
          else if char is ")"
            parens--

        fragments.push kind: 'function', dslCode: lines[i][squiggleStart+2..stopPos-1]
        lines[i] = lines[i].replace(lines[i][startPos..stopPos], "`@#{fragments.length - 1}`")

      i++
    # Collect bodies of multiline squiggly arrow functions
    else if /~>\s*$/.test lines[i]
      indent = lines[i].replace /^([ \t]*).*$/, '$1'
      indentRE = new RegExp '^' + indent.replace(/\t/g, '\\t') + '[ \t]'
      j = i + 1
      while j < lines.length and indentRE.test lines[j]
        j++
      fragments.push kind: 'function', dslCode: lines[i + 1 ... j].join('\n')
      lines[i] = lines[i].replace /~>\s*$/, "`@#{fragments.length - 1}`"
      for k in [i + 1 ... j] by 1 then lines[k] = ''
      i = j
    else
      i++
  coffeeCode = lines.join '\n'

  # # Step 2: AST reconnaissance

  # Walk the AST produced by CoffeeScript, record the variables used in each
  # scope, and associate each DSL fragment with the `vars` of the closest
  # scope.

  ast = CoffeeScript.nodes coffeeCode
  ast.vars = {}
  queue = [ast]
  while queue.length
    scopeNode = queue.shift()
    scopeNode.traverseChildren false, (node) ->
      {name} = node.constructor
      if name is 'Code'
        node.vars = {}
        for k, v of scopeNode.vars then node.vars[k] = v
        queue.push node
      else if name is 'Literal' and m = node.value.match /^@(\d+)$/
        fragments[+m[1]].vars = scopeNode.vars
      else if name is 'Assign'
        if v = node.variable?.base?.value
          scopeNode.vars[v] = {}
      true

  # # Step 3: Placeholders -> compiled code

  # Replace each placeholder with the compiled code for the corresponding
  # fragment.
  coffeeCode = coffeeCode.replace /`@(\d+)`/g, (_, id) ->
    f = fragments[+id]
    jsCode = require(opts.dsl ? 'apl').compile f.dslCode, {
      embedded: true
      kind: f.kind
      vars: for name, _ of f.vars then {name}
    }
    jsCode = "(function () { #{jsCode} })"
    if f.kind is 'expression' then jsCode += '()'
    "`#{jsCode}`"
