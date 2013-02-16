#!/usr/bin/env coffee-subscript

console.info JSON.stringify «(2=+⌿0=A∘.∣A)/A←⍳100»

countDown = ~>
  a ← ⍳ 10
  1 + ⌽ a

console.info JSON.stringify countDown()
