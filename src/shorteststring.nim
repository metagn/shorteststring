type
  ShortestString* = distinct uint

proc `==`*(a, b: ShortestString): bool {.borrow.}
proc `<`*(a, b: ShortestString): bool {.borrow.}

const shortestStringMaxSize* = sizeof(ShortestString) div sizeof(char)
const charBits = sizeof(char) * 8

template get(ss: ShortestString, i: int): char =
  char(
    (ss.uint shr (i * charBits)) and
      high(char).uint)

template set(ss: var ShortestString, i: int, c: char) =
  ss = ShortestString(ss.uint or
    (c.uint shl (i * charBits)))

proc `[]`*(ss: ShortestString, i: int): char {.inline.} =
  rangeCheck i >= 0 and i < shortestStringMaxSize
  get(ss, i)

proc `[]=`*(ss: var ShortestString, i: int, c: char) {.inline.} =
  rangeCheck i >= 0 and i < shortestStringMaxSize
  set(ss, i, c)

proc len*(ss: ShortestString): int =
  when true: # likely faster
    # unrolled loop
    {.push rangeChecks: off.}
    template doIndex(i: int) =
      if get(ss, i) == char(0):
        return i
    doIndex 0
    doIndex 1
    doIndex 2
    doIndex 3
    doIndex 4
    doIndex 5
    doIndex 6
    doIndex 7
    return 8
    {.pop.}
  else:
    if ss.uint <= 0xFF:
      1
    else:
      when sizeof(uint) == 2:
        2
      else:
        if ss.uint <= 0xFF_FF:
          2
        elif ss.uint <= 0xFF_FF_FF:
          3
        else:
          when sizeof(uint) == 4:
            4
          else:
            if ss.uint <= 0xFF_FF_FF_FF'u:
              4
            elif ss.uint <= 0xFF_FF_FF_FF_FF'u:
              5
            elif ss.uint <= 0xFF_FF_FF_FF_FF_FF'u:
              6
            elif ss.uint <= 0xFF_FF_FF_FF_FF_FF_FF'u:
              7
            else:
              8

template `[]`*(ss: ShortestString, i: BackwardsIndex): char =
  ss[ss.len - i.int]

template `[]=`*(ss: var ShortestString, i: BackwardsIndex, c: char) =
  ss[ss.len - i.int] = c

proc `[]`*(ss: ShortestString, sl: Slice[int]): ShortestString {.inline.} =
  rangeCheck sl.a >= 0 and sl.a < shortestStringMaxSize and sl.b >= 0 and sl.b < shortestStringMaxSize
  ShortestString((ss.uint shl (sl.a * charBits)) shr ((sl.len - sl.b + sl.a - 1) * charBits))

proc `[]=`*(ss: var ShortestString, sl: Slice[int], ss2: ShortestString) {.inline.} =
  rangeCheck sl.a >= 0 and sl.a < shortestStringMaxSize and sl.b >= 0 and sl.b < shortestStringMaxSize
  for i in sl:
    ss[i] = ss2[i - sl.a]

iterator items*(ss: ShortestString): char =
  # not unrolled because nim doesnt allow return
  {.push rangeChecks: off.}
  var i = 0
  while i < shortestStringMaxSize:
    let c = get(ss, i)
    if c == char(0):
      break
    yield c
    inc i
  {.pop.}

when not defined(js) and not defined(nimscript):
  when defined(gcc) or defined(llvm_gcc) or defined(clang):
    when shortestStringMaxSize == 2:
      proc swapEndian(a: uint): uint {.
          importc: "__builtin_bswap16", nodecl, noSideEffect.}
    elif shortestStringMaxSize == 4:
      proc swapEndian(a: uint): uint {.
          importc: "__builtin_bswap32", nodecl, noSideEffect.}
    elif shortestStringMaxSize == 8:
      proc swapEndian(a: uint): uint {.
          importc: "__builtin_bswap64", nodecl, noSideEffect.}
  elif defined(icc):
    when shortestStringMaxSize == 2:
      proc swapEndian(a: uint): uint {.
          importc: "_bswap16", nodecl, noSideEffect.}
    elif shortestStringMaxSize == 4:
      proc swapEndian(a: uint): uint {.
          importc: "_bswap", nodecl, noSideEffect.}
    elif shortestStringMaxSize == 8:
      proc swapEndian(a: uint): uint {.
          importc: "_bswap64", nodecl, noSideEffect.}
  elif defined(vcc):
    when shortestStringMaxSize == 2:
      proc swapEndian(a: uint): uint {.
          importc: "_byteswap_ushortest", nodecl, header: "<intrin.h>", noSideEffect.}
    elif shortestStringMaxSize == 4:
      proc swapEndian(a: uint): uint {.
          importc: "_byteswap_ulong", nodecl, header: "<intrin.h>", noSideEffect.}
    elif shortestStringMaxSize == 8:
      proc swapEndian(a: uint): uint {.
          importc: "_byteswap_uint64", nodecl, header: "<intrin.h>", noSideEffect.}
  when declared(swapEndian):
    template toLittleEndian(x: uint): uint =
      when cpuEndian == bigEndian:
        swapEndian(x)
      else:
        x

proc `$`*(ss: ShortestString): string =
  when nimvm:
    result = newStringOfCap(sizeof(ShortestString))
    for c in ss.items:
      result.add(c)
  else:
    when defined(js) or defined(nimscript) or (cpuEndian == bigEndian and not declared(swapEndian)):
      result = newStringOfCap(sizeof(ShortestString))
      for c in ss.items:
        result.add(c)
    else:
      # this should be faster than adding one at a time, but we still have to calculate length
      if ss.uint == 0:
        result = ""
      else:
        result = newString(ss.len)
        cast[ptr uint](addr result[0])[] = toLittleEndian(ss.uint)

iterator mitems*(ss: var ShortestString): var char =
  {.push rangeChecks: off.}
  var i = 0
  while i < shortestStringMaxSize:
    var c = get(ss, i)
    if c == char(0):
      break
    yield addr(c)[]
    ss[i] = c
    inc i
  {.pop.}

proc add*(ss: var ShortestString, c: char) =
  {.push rangeChecks: off.}
  var i = 0
  while i < shortestStringMaxSize:
    let c = get(ss, i)
    if c == char(0):
      set(ss, i, c)
      return
    inc i
  {.pop.}
  assert false, "string " & $ss & " is full"

proc toShortestString*(s: openarray[char], optimized: static bool = true): ShortestString =
  rangeCheck s.len <= shortestStringMaxSize
  when nimvm:
    for i, c in s:
      result[i] = c
  else:
    when defined(js) or defined(nimscript) or not optimized or (cpuEndian == bigEndian and not declared(swapEndian)):
      for i, c in s:
        result[i] = c
    else:
      if s.len == 0:
        # bypass nil
        result = ShortestString(0)
      else:
        # this might still be invalid memory access
        #ShortestString(cast[ptr uint](unsafeAddr s[0])[] and
        #  # use unsigned to bypass overflow
        #  (1u shl (result.len.uint * charBits.uint + 1u) - 1u))
        # XXX benchmark if this is faster (benchmark in general)
        let offset = shortestStringMaxSize - s.len
        result = ShortestString(
          (cast[ptr uint](unsafeAddr s[0])[].toLittleEndian shl
            (offset * charBits)) shr
              (offset * charBits))

template shortest*(s: static string): ShortestString =
  toShortestString(s)
