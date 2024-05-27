#【両端色付き付き正規表現にある（初期受理状態位置記号を内部に含む）？記号，＋記号区間の解消 written by Akira Ito】
import strutils, bicrePREPROrepeat
const availChars = {' '..'~'} # == " !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
const reservChars = {'*','+','.','?','(',')','[',']','|','\"','\\'} #; const reservStrs* = @[":>",":>^","<:","<:_"] + @['\' & reservChars] 
proc expandQmarkPmark*(biRE: string): string =
  var ptt = biRE & "$" # let => var #$
  proc expandQmark(i0, i1: int): int = # expand qmark α? to (α|[]) and return new current position i
    let seg = ptt[i0..<i1] # objective segment to be replaced
    let nseg = "(" & seg & "|[])"
    result = len(ptt[0..<i0] & nseg) # new current pos // 
    ptt = ptt[0..<i0] & nseg & ptt[i1+1..<ptt.len] # str changed; neglect star symbol '?' = ptt[i1+1]
  proc expandPmark(i0, i1: int): int = # expand pmark α+ to α{1,} and return new current position i
    let seg = ptt[i0..<i1] # objective segment to be replaced
    let nseg = seg & "{1,}"
    result = len(ptt[0..<i0] & nseg) # new current pos // 
    ptt = ptt[0..<i0] & nseg & ptt[i1+1..<ptt.len] # str changed; neglect star symbol '*' = ptt[i1+1]
  var i = 0 # position index of regex string
  # E -> :>1{ ( :>2{ :>3( '(' E ')'<:31 + 'a'<:32 + '<:'<:33 + ':>'<:34 )( '*'<:35 + '?'<:36)<:2 }*<:1 '|' }*
  proc E(): bool = # return psymbExist flag for recursive call (E) #?+
    var psymbExist: bool # ini or acc position symbol existance #?+
    while (true): # :>1
      while (true): ## :>2
        psymbExist = false # ini or acc position symbol existance #?+
        let i0 = i # starting position index of segment to be replaced #?+
        if ptt[i] == '(': ### :>3 
          #token[i] = (avachar, "(") #!!!
          inc(i); psymbExist = E() # ini or acc pos symbol exists or not #?+
          if ptt[i] != ')': raise newException(IOError, "NOT ')'")
          else: ### <:31
            #token[i] = (avachar, ")") #!!!
            inc(i)
        elif ptt[i] in availChars - reservChars + {'[','\\','.'} - {':','<'}: # ptt[i] == 'a': ### <:32
          if ptt[i] == '[':
            i += ptt[i..^1].find(']') 
            #if i == i0 + 1: token[i0] = (empstr, "[]"); helperPr = (true, @[], @[]) #!4
            #else: token[i0] = (chclass, ptt[i0+1..<i]) # i0 = i;  # skip '[...]' for char class
          elif ptt[i] == '\\': inc(i) #token[i] = (escchar, $ptt[i+1]); inc(i) # skip one char for escape seq
          elif ptt[i] == '.': discard #token[i] = (dotany, ".") #; discard # match any single char
          else: discard #token[i] = (avachar,$ptt[i])
          inc(i)
        elif ptt[i] == ':':
          if ptt[i+1] == '>': # init state pos symbol ### <:33
            result = true # ini pos symbol exists #?+
            inc(i); inc(i)
            if ptt[i] == '^': inc(i); inc(i) #token[i0] = (initpos, $ptt[i0+3]); inc(i); inc(i) # with additional one char label
            else: discard #token[i0] = (initpos, "")
          else: # ':' is not init state pos symbol (an ordinary char ### <:32)
            inc(i) #!!
        elif ptt[i] == '<':
          if ptt[i+1] == ':': # acc state pos symbol ### <:34
            result = true # acc pos symbol exists #?+
            inc(i); inc(i)
            if ptt[i] == '_': inc(i); inc(i) #token[i0] = (accpos, $str[i0+3]); inc(i); inc(i) # with additional one char label
            else: discard #token[i0] = (accpos, "")
          else: # '<' is not acc state pos symbol (an ordinary char ### <:32)
            inc(i) #!!
        else: raise newException(IOError, "NOT '(','a','[','\\','.','<',':'") # ptt[i] != '(' and ptt[i] != 'a' and ...
        let i1 = i # ending position index (+1) of segment to be replaced #+?
        if ptt[i] == '*':# or ptt[i] == '+': ### <:35
          inc(i)
# ---------------------------------------------------------------------------------------- ↓ added for pmark
        if ptt[i] == '+': 
          if psymbExist: i = expandPmark(i0,i1) else: inc(i) #          echo ptt," i=",i
# ---------------------------------------------------------------------------------------- 
        if ptt[i] == '?': 
          if psymbExist: i = expandQmark(i0,i1) else: inc(i) ### <:36 #          echo ptt," i=",i
# ---------------------------------------------------------------------------------------- ↑ added for qmark
        if ptt[i] == '|' or ptt[i] == '$' or ptt[i] == ')': # ※ one charactor look-ahead
          break ## <:2  (concat)
      # end of concat operators
      # end of + operators
      if ptt[i] != '|':
        break # <:1
      inc(i) # and repeat when ptt[i] == '|'
    return result #result #?+
  # end of E()
  discard E()
  if ptt[i] != '$': raise newException(IOError, "NOT '$'")
  return expndrepeat(ptt[0..^2]) # augmented symbol '$' deleted # return expansion of α{1,} #?+
# end of expandQmarkPmark()
when isMainModule:
  var ptt = r"((a:>b)?c<:)*" # r"((a<:b)+c)*" # r"(a?(b:>c)?<:d+)+"#=>((a?((b:>c)|[])<:d+)|(a?((b:>c)|[])d+)(a?((bc)|[])d+)*(a?((bc)|[])<:d+)) # r"(a|:>(b<:c)+d)?ef?(<:?g)*"#=>((a|:>(bc)*(b<:c)d)|[])ef?(<:?g)* #
  echo "original regex = ", ptt
  echo "expanded regex = ", expandQmarkPmark(ptt)
