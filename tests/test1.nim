import shorteststring

block:
  for s in ["", "a", "ab", "abc", "abcd", "abcde", "abcdef", "abcdefg", "abcdefgh"]:
    block:
      let ss = s.toShortestString
      doAssert $ss == s
      for i in 0 ..< s.len:
        doAssert s[i] == ss[i]
    block:
      let ss = s.toShortestString(optimized = false)
      doAssert $ss == s
      for i in 0 ..< s.len:
        doAssert s[i] == ss[i]
  doAssert shortest"ab" < shortest"abc"
  doAssert shortest"ab" < shortest"ac"
  doAssert shortest"ab" < shortest"bb"
  doAssert toShortestString"ab" < toShortestString"abc"
  doAssert toShortestString"ab" < toShortestString"ac"
  doAssert toShortestString"ab" < toShortestString"bb"
