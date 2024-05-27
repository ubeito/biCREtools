#【両端色付き付き正規表現の繰り返し回数記号有りから無しへの変換 written by Akira Ito】
import strutils
const availChars = {' '..'~'} # == " !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
const reservChars = {'*','+','.','?','(',')','[',']','|','\"','\\'} #; const reservStrs* = @[":>",":>^","<:","<:_"] + @['\' & reservChars] 
proc expndrepeat*(biRE: string): string = 
  var str = biRE & "$" # let => var #$
  var i = 0 # position index of regex string
  proc parseNat():int = #$
    if not str[i].isDigit: return -1 # no digits
    while str[i].isDigit: 
      let d = str[i].int; result = result * 10 + d - '0'.int; inc(i) # str[i].int -'0'.int; inc(i) ==> # Error: attempting to call routine: 'int'
  #echo parseNat()
  type Boolpair = enum false_false, false_true, true_false, true_true
  proc trianglepsets(seg: string): Boolpair = # (bool, bool) ==> Error: set is too large
    if seg.find(":>") == -1 and seg.find("<:") == -1: result = true_true # == -1 <==> not found
    if seg.find(":>") == -1 and seg.find("<:") != -1: result = true_false
    if seg.find(":>") != -1 and seg.find("<:") == -1: result = false_true
    if seg.find(":>") != -1 and seg.find("<:") != -1: result = false_false
  proc evicttris(seg: string): (string, string, string) = 
    var leftonly, rightonly, neither :string
    var j = 0; let L = seg.len
    while (j < L):
      if j+1 < L and seg[j..j+1] == ":>":
        if j+3 < L and seg[j+2] == '^': # ":>^z"
          leftonly &= seg[j..j+3]; rightonly &= ""; neither &= ""; j += 4
        else: # ":>"
          leftonly &= seg[j..j+1]; rightonly &= ""; neither &= ""; j += 2
      if j+1 < L and seg[j..j+1] == "<:":
        if j+3 < L and seg[j+2] == '_': # "<:_z"
          leftonly &= ""; rightonly &= seg[j..j+3]; neither &= ""; j += 4
        else: # ":>"
          leftonly &= ""; rightonly &= seg[j..j+1]; neither &= ""; j += 2
      else: 
        leftonly &= $seg[j]; rightonly &= $seg[j]; neither &= $seg[j]; j += 1
    return (leftonly, rightonly, neither)
  proc expandD(m: int, i0, i1, i2: int): int = # expand α{d+} and return new current position i
    let seg = str[i0..<i1] # objective segment to be repeated
    var nseg: string
    let (leftonly, rightonly, neither) = evicttris(seg)
    let ipapEmptiness = trianglepsets(seg) # get positions of ":>"s and "<:"s
    case ipapEmptiness # whether symbols ":>"s, "<:"s exist or not in the segment # selector must be of an ordinal type, float or string
    of true_true: # having nether: α[,]{m} # expand α=str[i0..<i1] to "α..α" if m\ge 1, or to "ε" if m=0
      if m >= 1: nseg = seg.repeat(m) 
      else: nseg = "" # m=0
    of false_true: # having only ini (left) syms: α[:>,]{m} # expand to α[:>,]α[,]{m-1} if m\ge 1, to "ε" if m=0
      if m >= 1: nseg = seg & neither.repeat(m-1)
      else: nseg = ""
    of true_false: # having only acc (right) syms: α[,<:]{m} # expand to α[,]{m-1}α[,<:] if m\ge 1, to "ε" if m=0
      if m >= 1: nseg = neither.repeat(m-1) & seg
      else: nseg = ""
    of false_false: # having both: α[:>,<:]{m} # expand # α[:>,]α[,]{m-2}α[,<:], m≧2
      if m >= 2: nseg = leftonly & neither.repeat(m-2) & rightonly
      elif m == 1: nseg = seg # α[:>,<:], m = 1
      else: nseg = "" # m = 0.
    result = len(str[0..<i0] & nseg) # new current pos // 
    str = str[0..<i0] & nseg & str[i2..<str.len] # str changed; neglect part of curly braces {m} = str[i1..<i2] 
  proc expandD1D2(m, n: int, i0, i1, i2: int): int = # expand α{d+,d+} and return new current position i
    let seg = str[i0..<i1]
    var nseg: string
    let (leftonly, rightonly, neither) = evicttris(seg)
    let ipapEmptiness = trianglepsets(seg)
    case ipapEmptiness # (ipset == {}, apset == {}) 
    of true_true: # of (true, true): α[,]{m,n}
      if m >= 0 and n - m >= 0: nseg = seg.repeat(m) & (seg & '?').repeat(n-m) #  α[,]{m}(α[,]?){n-m}, m,n-m≧0
      else: nseg = ""
    of false_true: # having ini (left) symbols only: α[:>,]{m,n} 
      if m >= 1 and (n - m >= 0): nseg = seg & neither.repeat(m-1) & (neither & '?').repeat(n-m) # α[:>,]α[,]{m-1}(α[,]?){n-m}, m≧1,n-m≧0
      elif m == 0 and n >= 1: nseg = seg & (neither & '?').repeat(n-1) # α[:>,](α[,]?){n-1}, m=0,n≧1
      else: nseg = "" # m=0,n=0
    of true_false: # having acc (right) symbols only: α[,<:]{m,n}
      if m >= 1 and (n - m >= 0): nseg = (neither).repeat(m-1) & (neither & '?').repeat(n-m) & seg # α[,]{m-1}(α[,]?){n-m}α[,<:], m≧1,n-m≧0
      elif m == 0 and n >= 1: nseg = (neither & '?').repeat(n-1) & seg # (α[,]?){n-1}α[,<:], m=0,n≧1
      else: nseg = "" # m=0,n=0
    of false_false: # having both: α[:>,<:]{m,n} 
      if m >= 2 and (n - m >= 0): nseg = leftonly & (neither).repeat(m-2) & (neither & '?').repeat(n-m) & rightonly # α[:>,]α[,]{m-2}(α[,]?){n-m}α[,<:], m≧2,n-m≧0
      elif (m == 1 or m == 0) and n >= 2: nseg = '(' & seg & '|' & leftonly & (neither & '?').repeat(n-2) & rightonly & ')' # α[:>,<:] | α[:>,]α[,]{0}(α[,]?){n-2}α[,<:], m=1,0,n≧2
      elif (m == 1 or m == 0) and n == 1: nseg = seg # α[:>,<:], m=1,0,n=1
      else: nseg = "" # ε, m=0,n=0
    result = len(str[0..<i0] & nseg) # new current pos // 
    str = str[0..<i0] & nseg & str[i2..<str.len] # str changed; neglect part of curly braces {m} = str[i1..<i2] 
  proc expandD1C(m: int, i0, i1, i2: int): int = # expand α{d+,} and return new current position i
    let seg = str[i0..<i1]
    var nseg: string
    let (leftonly, rightonly, neither) = evicttris(seg)
    let ipapEmptiness = trianglepsets(seg)
    case ipapEmptiness # (ipset == {}, apset == {}) 
    of true_true: # of (true, true): α[,]{m,}
      if m >= 1: nseg = seg.repeat(m) & seg & '*' # α[,]{m}α[,]*, m≧0
      else: nseg = seg & '*' # α[,]*, m=0
    of false_true: # having ini (left) symbols only: α[:>,]{m,}
      if m >= 1: nseg = seg & neither.repeat(m-1) & neither & '*' # α[:>,]α[,]{m-1}α[,]*, m≧1
      else: nseg = seg & neither & '*' # α[:>,]α[,]*, m=0
    of true_false: # having acc (right) symbols only: α[,<:]{m,}
      if m >= 1: nseg = (neither).repeat(m-1) & neither & '*' & seg # α[,]{m-1}α[,]*α[,<:], m≧1
      else: nseg = neither & '*' & seg  # α[,]*α[,<:], m=0
    of false_false: # having both: α[:>,<:]{m,}
      if m >= 2: nseg = leftonly & (neither & '*').repeat(m-2) & rightonly # α[:>,]α[,]{m-2}α[,]*α[,<:], m≧2
      elif m == 1: nseg = '(' & seg & '|' & leftonly & neither & '*' & rightonly & ')' # α[:>,<:] | α[:>,]α[,]*α[,<:], m=1
      else: nseg = '(' & '|' & seg & '|' & leftonly & neither & '*' & rightonly & ')' # ε | α[:>,<:] | α[:>,]α[,]*α[,<:], m=0
    result = len(str[0..<i0] & nseg) # new current pos // 
    str = str[0..<i0] & nseg & str[i2..<str.len] # str changed; neglect part of curly braces {m} = str[i1..<i2] 
  proc expandCD2(n: int, i0, i1, i2: int): int = # expand α{,d+} and return new current position i
    let seg = str[i0..<i1]
    var nseg: string
    let (leftonly, rightonly, neither) = evicttris(seg)
    let ipapEmptiness = trianglepsets(seg)
    case ipapEmptiness # (ipset == {}, apset == {}) 
    of true_true: # of (true, true): α[,]{,n}
      if n >= 1: nseg = (seg & '?').repeat(n) #(α[,]?){n}, n≧0
      else: nseg = "" # (α[,]?){0} = ε, n=0
    of false_true: # having ini (left) symbols only: α[:>,]{,n}
      if n >= 1: nseg = seg & (neither & '?').repeat(n-1) # α[:>,](α[,]?){n-1}, n≧1
      else: nseg = "" # ε, n=0
    of true_false: # having acc (right) symbols only: α[,<:]{,n}
      if n >= 1: nseg = (neither).repeat(n-1) & seg # # (α[,]{n-1})?α[,<:], n≧1
      else: nseg = neither & '*' & seg  # α[,]*α[,<:], m=0
    of false_false: # having both: α[:>,<:]{,n}
      if n >= 2: nseg = leftonly & (neither & '?').repeat(n-2) & rightonly # α[:>,](α[,]?){n-2}α[,<:], n≧2
      elif n == 1: nseg = '(' & seg & '|' & ')' # α[:>,<:] | ε, n=1
      else: nseg = "" # ε, n=0
    result = len(str[0..<i0] & nseg) # new current pos // 
    str = str[0..<i0] & nseg & str[i2..<str.len] # str changed; neglect part of curly braces {m} = str[i1..<i2] 
  # E -> :>1{ ( :>2{ :>3( '(' E ')'<:31 + 'a'<:32 + '<:'<:33 + ':>'<:34 )( '*'<:35 + '?'<:36)<:2 }*<:1 '|' }*
  proc E() = 
    while (true): # :>1
      while (true): ## :>2
        let i0 = i  # starting position index of segment to be repeated #$
        if str[i] == '(': ### :>3 
          #token[i] = (avachar, "(") #!!!
          inc(i); E()
          if str[i] != ')': raise newException(IOError, "NOT ')'")
          else: ### <:31
            #token[i] = (avachar, ")") #!!!
            inc(i)
        elif str[i] in availChars - reservChars + {'[','\\','.'} - {':','<'}: # str[i] == 'a': ### <:32
          if str[i] == '[':
            i += str[i..^1].find(']') 
            #if i == i0 + 1: token[i0] = (empstr, "[]"); helperPr = (true, @[], @[]) #!4
            #else: token[i0] = (chclass, ptt[i0+1..<i]) # i0 = i;  # skip '[...]' for char class
          elif str[i] == '\\': inc(i) #token[i] = (escchar, $str[i+1]); inc(i) # skip one char for escape seq
          elif str[i] == '.': discard #token[i] = (dotany, ".") # discard # match any single char
          else: discard ##token[i] = (avachar,$str[i])
          inc(i)
        elif str[i] == ':':
          if str[i+1] == '>': # init state pos symbol ### <:33
            inc(i); inc(i)
            if str[i] == '^': inc(i); inc(i) #token[i0] = (initpos, $str[i0+3]); inc(i); inc(i) # with additional one char label
            else: discard #token[i0] = (initpos, "")
          else: # ':' is not init state pos symbol (an ordinary char ### <:32)
            inc(i) #!!
        elif str[i] == '<':
          if str[i+1] == ':': # acc state pos symbol ### <:34
            inc(i); inc(i)
            if str[i] == '_': inc(i); inc(i) #token[i0] = (accpos, $str[i0+3]); inc(i); inc(i) # with additional one char label
            else: discard #token[i0] = (accpos, "")
          else: # '<' is not acc state pos symbol (an ordinary char ### <:32)
            inc(i) #!!
        else: raise newException(IOError, "NOT '(','a','[','\\','.','<',':'") # str[i] != '(' and str[i] != 'a' and ...
# ---------------------------------------------------------------------------------------- ↓ added
        let i1 = i # ending position index (+1) of segment to be repeated #$
        if str[i] == '{': ### <:35 for bounded repeat
          var d1, d2: int
          inc(i)
          if str[i].isDigit:
            d1 = parseNat() # discard # "{d+"
            if str[i] == ',': # "{d+,"
              inc(i) 
              if str[i] == '}': inc(i); i = expandD1C(d1, i0, i1, i) # echo "{d+,} = ", d1 # "{d+,}" # <:_B
              else: # "{d+,X"
                d2 = parseNat()
                if d2 == -1: raise newException(IOError, "NOT digit") 
                else: # "{d+,d+"
                  #inc(i)
                  if str[i] == '}': inc(i); i = expandD1D2(d1, d2, i0, i1, i) # echo "{d+,d+} = ", d1, ", ", d2 # "{d+,d+}" <:_A
                  else: raise newException(IOError, "NOT '}'")
            elif str[i] == '}': # "{d+}"
              inc(i); i = expandD(d1, i0, i1, i) # echo "{d+} = ", d1 # "{d+}" # <:_C
            else: raise newException(IOError, "NOT ',','}'")
          elif str[i] == ',':
            inc(i) # "{,"
            d2 = parseNat() 
            if  d2 == -1: raise newException(IOError, "NOT digit")
            elif str[i] == '}': inc(i); i = expandCD2(d2, i0, i1, i) # echo "{,d+} = ", d2 # "{,d+}" <:_D
            else: raise newException(IOError, "NOT '}'")
          else: raise newException(IOError, "NOT '{',','")
          # let i2 = i # ending position index (+1) of repeat marker "{...}" #$
# ---------------------------------------------------------------------------------------- ↑ added
        if str[i] == '*' or str[i] == '+': ### <:35
          inc(i)
        if str[i] == '?': ### <:36
          inc(i)
        if str[i] == '|' or str[i] == '$' or str[i] == ')': # ※ one charactor look-ahead
          break ## <:2  (concat)
      # end of concat operators
      # end of + operators
      if str[i] != '|':
        break # <:1
      inc(i) # and repeat when str[i] == '|'
    return ##result
  # end of E()
  E()
  if str[i] != '$': raise newException(IOError, "NOT '$'")
  return str[0..^2] # augmented symbol '$' deleted 
# end of expandrep()
when isMainModule:
  var str = r":>((a<:b){1,}c)*"#=> :>((ab)*(a<:b)c)*=:>((a<:b)+c)*:test2 # r"(a:>b){1,}<:"#=> (a:>b)(ab)*<:
# r":>^N97(8|9)[- ]?:>^O([0-9][- ]?){9}[0-9xX]<:" # r":>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)<:\.){4}" # r":>[a-zA-Z0-9.!#$%&’*+/=?ˆ_‘{|}˜-]+@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?<:\.)*" # r":>(a?){3}(a{4})*<:" # r":>(0{8}0*|(0{3}|0{5})*)<:"
# r":>a{,3}<:" # r":>a{3,}<:" # r":>a{3,4}<:" # r":>a{3}<:" # ==> :>aaa<: 
# r":>(0:><:1){3}<:" # ==> :>(0:>1)(01){1}(0<:1)
# r":>((a<:b){2}c){3}" # ==> :>((ab)(ab)c)((ab)(ab)c)((ab)(a<:b)c)
# r":>((a{4}<:b){3}<:c){2}" # ==> :>((a{4}b){3}c)((a{4}b){2}(a{4}<:b)<:c)  # r":>((a<:b){2}c){3}" # ==> :>((ab)(ab)c){2}(ab)(a<:b)c
# r"(a(b:>a*<:b){3}a|b){4}" # ==> (a(b:>a*b)(ba*b){2}a|b)(a(ba*b){3}a|b){2}(a(ba*b){2}(ba*<:b)a|b)
# r":>(((a<:b){2}cd){3}ef){4}" # ==> :>(((ab){2}cd){3}ef){3}(((ab){2}cd){2}((ab)(a<:b)cd)ef)
# r":>(((a<:b){2}c<:d){3}e<:f){4}" # ==>(((ab){2}cd){3}ef){3}(((ab){2}cd){2}((ab)(a<:b)c<:d)e<:f)
# r":>(0|1(<:_b01*<:_c0|11){3}1<:_d0){2}<:_a" # ==> :>(0|1(01*0|11){3}10)(0|1(01*0|11){2}(<:_b01*<:_c0|11)1<:_d0)<:_a 
# non repeat # r":>(0|1)*1(0|1)<:(0|1)<:" # r":>(0|1(<:_B01*<:_C0|11)*1<:_D0)*<:_A" # r":>(0?0?<:1)*" # r":>1?(01)*0?<:" # r"(a|:>b)*<:" # r":>([A-Z][a-z]*<: )*" # r":>(0:><:1)*<:" #
  echo "expanded regex = ", expndrepeat(str)
##############################################################################################################################
#     +---------------------------------------+
#     ↓                         ↑ {$}         ↑ ε                  ↑: node labeled '＋' code
# E ->○ - - - - - - T - - - - ->◎---- | ---->○                    <== <:1
#     | ←--------- ε ---------+ ↑\ {)}                             ↑: node labeled '・' code
#     ↓/         {(,a,[,\,:,<} \/ {$,|,)}        
# T ->○ - - - - - - F - - - - >◎<= = = = = =                      <== <:2
#     ↓ {(,a,[,\,:,<}              ↓ {)}      ↑                    ↑: node labeled '(E)' code
# F ->○--- ( --->○ - - - E - - - ->○--- ) --->◎                   <== <:31
#     |\                                       \↑             ↑    ↑: node labeled 'a' code, ↑: node labeled '*' code
#     | +-------- a OR [X] OR \b OR [] ------->◎-- * OR + -->◎   <== <:32, <:35
#     |\                                     ↑／|\            ↑    ↑: node labeled ':>' code, ↑: node labeled '?' code
#     | +------------ :> OR :>^b ----------->◎ | +---- ? --->◎   <== <:33, <:36
#      \                                     ↑／                   ↑: node labeled '<:' code
#       +------------ <: OR <:_b ----------->◎                    <== <:34
# ※ For right associativities of '*','+', rule "F -> (a + [x])('*' + '+')" must change to "F -> (a + [x])('*' + '+')*" # r":>a*+<:": => error
##############################################################################################################################
# X --> '{' d+ ',' d+ '}' <:_A | '{' d+ ',' '}' <:_B | '{' d+ '}' <:_C | '{' ',' d+ '}' <:_D
# X --- { --->○--- d+ --->○--- , --->○--- d+ --->○--- } --->◎--->   <== <:_A
#             |           |          +---  } --->◎-------------->   <== <:_B
#             |           +--- } --->◎-------------------------->   <== <:_C
#             +--- , ---->○--- d+ --->○--- } --->◎-------------->   <== <:_D
##############################################################################################################################
# Y --> ':>' ( ε | '^z' ) | '<:' ( ε | '_z' )
# Y --->○--- :> --->◎--- ^z --->◎
#       ↓
#       +--- <: --->◎--- _z --->◎
##############################################################################################################################
#expanded regex = :>^N97(8|9)[- ]?:>^O([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)([0-9][- ]?)[0-9xX]<: