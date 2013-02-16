#!/usr/bin/env node
(function() {
  var countDown;

  console.info(JSON.stringify((function (_w, _a) {
  var _ = require('apl').createGlobalContext();
  var _0 = {};
;
return _["/"](_0["A"] = _["⍳"](100), _["="](_["⌿"](_["+"])(_["="](_["∘."](_["∣"])(_0["A"], _0["A"]), 0)), 2));

})()));

  countDown = (function (_w, _a) {
  var _ = require('apl').createGlobalContext();
  var _0 = {};
;
_0["a"] = _["⍳"](10);
return _["+"](_["⌽"](_0["a"]), 1);

});

  console.info(JSON.stringify(countDown()));

}).call(this);
