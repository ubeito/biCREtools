#【両端色付き正規表現に対応する位置εオートマトンの入力テキストに対するマッチング written by Akira Ito】
import bicrePARSERmodule, bicrePREPROrepeat, tables, sequtils, parseopt, sets
export bicrePARSERmodule, bicrePREPROrepeat # for bicre.nim
#var ptt = r":>^R[+-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B"; var xs = @["12.34","-1.23","1234","+123",".123","123.","."] # DCFA accepting binary fractional or integer numbers 
#var ptt = r":>\[([a-z ]*)\]\((https?://[^)]+)\)<:"; var xs = @["[my link](https://example.com)","[ mylink ](http:// e1xAa$m!p/l-e.c]o{m)"]
#var ptt = r":>^00:>^10:>^201<:_41<:_51<:_6"; var xs = @["01","011","0111","001","0011","00111","0001","00011","000111"] # biDCFA accepting 9 different unary languages
#var ptt = r"(a|:>b)*<:"; var xs = @["baba" ,"abab","bbaa","ab"] # monoCRE expressing starts b
#var ptt = r"empty:><:string"; var xs = @["empty string", "emptystring",""] # Beware the syntax
#var ptt = r":>([A-Z][a-z]*<: )*"; var xs = @["Abcd Efgh","Ab ","Abcd","ab Cd"] # monoCRE expressing name of streats
#var ptt = r":>(0|1(<:_B01*<:_C0|11)*1<:_D0)*<:_A"; var xs = @["0110","0111","1000","1001"] # DCFA classifying multiple of 6 binaries
#var ptt = r":>(0|1)*1(0|1)<:(0|1)<:"; var xs = @["001","1001","0010","0101","0110"] # monoDCFA accepting the 2nd or 3rd from right end is 1  
#var ptt = r":>(0:><:1)*<:"; var xs = @["1010","0101","0110","100","010"] # monoCFA accepting both 0,1 not repeat  
#var ptt = r":>1?(01)*0?<:"; var xs = @["1010","0101","0110","100","010"] # normal RE expressing both 0,1 not repeat
#var ptt = r":>(0?0?<:1)*"; var xs = @["1000","0101","0110","0011","0001"] # monoCRE expressing 0's not continue more than 3
#var ptt = r"(a(b:>a*<:b)*a|b)*"; var xs = @["ababab","abababab","bababa","baba","bb","baab","aa"] # monoDCFA {\cal D}_3 in Ref [10]
#var ptt = r"(0*<:2:>1*)*"; var xs = @["012","210","021"] # monoCRE expressing not contain 01
#var ptt = r"(aa(ab|ba)*bb|ab|ba|bb(ab|b:><:a)*aa)*"; var xs = @["ab","aabb","aaaaaabbbbbb","abab","aa","bb"] # monoDCFA expressing depth-6 buffer
#var ptt = r"((b:><:b|aa)*(b:><:a|ab)(a:><:a|bb)*(a:><:b|ba))*"; var xs = @["aabb","abab","aa","ab","bba"] # monoDCFA expressing both a and b are even
#var ptt = r":>(a|b)*a(a|b)(a|b)<:_Y|:>((a|b)*b(a|b)(a|b)|(a|b)?|(a|b)(a|b))<:_N"; var xs = @["abaab","bab","ab","bb",""] # self-verifying DCFA accepting the 3rd from right end is a
#var ptt = r":>((0|(0|1<:_B0)(000<:_B0)*001)(<:_R1(0<:_G00<:_B0)*0<:_G01)*<:_R0)*(0|1<:_B0)(000<:_B0)*0<:_G"; var xs = @["0","1","00","0000"] # Example 1 CFA in first IEICE paper
##var ptt = r":>(0<:_R0)*0(0<:_G00<:_B)"; var xs = @["0000"] #var ptt = r":>(0<:_R0|00<:_G)"; var xs = @["00"] # test for the above ptt
#var ptt = r"(:>a*bb*<:a)*"; var xs = @["abb","bba","baba","b"] # DCFA D21 accepting right end is b
#var ptt = r"((b|a:>a*b)(a|bb*<:_1a)<:_2)*"; var xs = @["abbb","bbaa","baba","b"] # DCFA D22 accepting the 2nd from right end is b
#var ptt = r"((<:(b|a:>a*b)a(ba)*a)*<:(b|a:>a*b)(a(ba)*b<:b|b)((a|bb*<:a)<:b(ab)*<:b)*(a|bb*<:a)<:(b(ab)*aa|a))*"; var xs = @["abbb","bbaa","baba","b"] # DCFA D23 accepting the 3rd from right end is b
#var ptt = r"((:>a*cc*<:_2a)*:>a*(b|cc*<:_2b)(b*<:_1cc*<:_2b)*b*<:_1(cc*<:_2a|a))*"; var xs = @["abcb","bcc","cba","b"] # DCFA D31 accepting right end is b or c
#var ptt = r":>((0|1|2)*1(0|1|2)<:_1|(0|1|2)*2(0|1|2)<:_2)"; var xs = @["012","120","201","210"] # NCFA N3,2 accepting r3,2 the 2nd from right end is 1 or 2
#var ptt = r":>(aa|(ab|b)(ab)*(aa|b))*<:"; var xs = @["abbb","babb","bbbb","baa","bba", "ab"] # DFA K3 accepting Lr(3) right end is a run (consective substring of a or b) of even length
##var ptt = r":>(((a|b)*b)?(aa)*aa|(((a|b)*a)?(bb)*bb)?)<:"; var xs = @["abbb","babb","bbbb","baa","bba", "ab"] # test for the above ptt
#var ptt = r":>((001|011|101|111)<:_0|(010|011|110|111)<:_1|(100|101|110|111)<:_2)"; var xs = @["001","010","100","011","101","110","111","000"] # worstly mixed NCFA with 3 colors
#var ptt = r":>(0*1<:_B0)*0*<:_A"; var xs = @["010","101","110","11", ""] # DFA transformed NFA having not consecutive 1's and ends with 0 (or "") or having not consecutive 1's and ends with 1
#var ptt = r"(01*0:>1*)*<:"; var xs = @["0101","110","001","1000"] # monoCRE expressing contains even number of 0's
#var ptt = r":>.*abcabac.*<:"; var xs = @["ababcababcabacba"] # a KMP string matching example in my lecture of "Algorithms and Data structures" (taken from a japanese textbook)
##var ptt = r":>.*(ab.*cd<:_1|ef.*gf<:_2)" # "The XFA recognizing both .*ab.*cd and .*ef.*gh without state space blowup"
##var ptt = r":>(expr1<:_1|.*expr2<:_2)" # "Simpliﬁed NXFA construction step for parallel concatenation expr1#expr2"
# [numbered repeat examples] -------------------------------------------------------------------------------------
var ptt = r":>[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?<:\.)*"; var xs = @["webmaster@example.com",r"a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-@a-zA-Z0-9.a-zA-Z0-9.a-zA-Z0-9"] # email addresses in HTML Living Standard
#var ptt = r":>^N97(8|9)[- ]?:>^O([0-9][- ]?){9}[0-9xX]<:"; var xs = @["4-00-310101-4","978-4-00-310101-8"] # "13-digit new ISBN (not sum check)" "10-digit old ISBN (not sum check)" "neither ISBN code"
#var ptt = r":>((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)<:\.){4}"; var xs = @["230.201.000.11", "192.0.2.0", "198.51.100.0","256.0000..1"] # monoCRE expressing IPv4 decimal address
#var ptt = r":>(a?){3}(a{4})*<:"; var xs = @["","a","aa","aaa","aaaa","aaaaa"] # equality: (epsilon + a + aa + ... + a^{n-1})(a^n)* == a*
#var ptt = r":>(0{8}0*|(0{3}|0{5})*)<:"; var xs = @["","000","00000","00000000","0","00"] # equality: (0{c})0*|(0{a}|0{b})* == ((0{a})|(0{b}))* <==> \forall n\ge c, \exists x,y[n = ax + by]
var p = initOptParser(ptt & xs) # for command line execution
ptt = ""; xs = @[]
p.next(); ptt = p.key; xs = p.remainingArgs

ptt = expndrepeat(ptt) # repeat expanded regex

func pttnum*(ptt: string): string = 
  for i in 0..<len(ptt): result &= "\"" & ptt[i] & "\"[" & $i & "] "
type Follow = Table[int, seq[int]]; type Token = Table[int, (Tokenkind, string)] 
let (follow, token) = biCREfollowtoken(ptt) # (Table[int, seq[int]], Table[int, (Tokenkind, string)]) # tried to move to when section but failed due to its usage in proc's
#echo "follow = ", follow ; echo "token = ", token # Below, two functions follow & token are assumed as global
func getavaistates*(follow: Follow): seq[int] = # extract states for state transition (excluding not-seeing symbols in input strings)
  for k in follow.keys: result &= k # mark-after states
  for v in follow.values: # mark-before states
    for i in v: result &= i
  result = deduplicate(result)
let avaistates = getavaistates(follow)
func getinisetaccset*(avaistates: seq[int], token: Token): (seq[int], seq[int]) = # set of ini and acc states indeces
  var iniset, accset: seq[int]
  for i in avaistates:
    if token[i][0] == initpos: iniset &= i elif token[i][0] == accpos: accset &= i # initpos, accpos: tokenKind
  return (iniset, accset)
let (iniset, accset) = getinisetaccset(avaistates, token)
#echo "iniset = ", iniset.mapIt((it, token[it][1])), "; accset = ", accset.mapIt((it, token[it][1]))

type Config* = Table[int, seq[string]] # ex. state i contains set of colors @["R","B"]; "" represents mono-color

func eclosure(curconfig: Config, follow: Follow): Config = # mark-after confing --> follow function --> mark-before config
  for k in curconfig.keys: result[k] = @[] # initialization of next configuration
  for i in curconfig.keys:
    if curconfig[i] != @[] and follow.hasKey(i): # added 'and follow.hasKey(i)'
      for j in follow[i]: result[j] &= curconfig[i]; result[j] = deduplicate(result[j])

func geteinitConfig*(avaistates, iniset: seq[int], token: Token, follow: Follow): Config = # colors of states to trace nondeterministic transition
  var initConfig: Config
  for i in avaistates: initConfig[i] = @[] # configuration does contain only informations of available states
  for i in iniset: initConfig[i] &= token[i][1] #; echo "init Config = ", initConfig # initial configuration (mark-after)
  result = eclosure(initConfig, follow) #; echo "einitConfig = ", einitConfig # initial configuration (mark-before)

#func
proc runonfrom*(x: string, einitconfig: Config, token: Token, follow: Follow): Config = 
  proc delta(curconfig: Config; symbol: char): Config = # mark-before state --> read one text symbol --> mark-after state
    for k in curconfig.keys: result[k] = @[] # initialization of next configuration
    for i in curconfig.keys:
      let tkstr = token[i][1] # ith token string 
      if curconfig[i] != @[]:
        case token[i][0] # TokenKind
        of avachar, escchar:
          if symbol == tkstr[0]: result[i] &= curconfig[i]; result[i] = deduplicate(result[i])
        of dotany:
          if symbol in availchars: result[i] &= curconfig[i]; result[i] = deduplicate(result[i])
        of chclass:
          var ccset: set[char] = {}
          var j = 0
          var e = 0
          if tkstr[0] == '^': # if tkstr[0] != '^' and tkstr[0] != '-': no action
            inc(j)
            if tkstr[1] == '-': ccset = ccset + {'-'}; inc(j) #
          elif tkstr[0] == '-': ccset = ccset + {'-'}; inc(j) # 
          if tkstr[^1] == '-': e = 1; ccset = ccset + {'-'} # tkstr.len = tkstr.len - 1
          while j < len(tkstr)-e: # tkstr[^1] != '-' # tkstr[j] in availchars 
            #if tkstr[j] == '\\': ccset = ccset + {tkstr[j+1]}; j = j + 1 # "+\-" ==> '+' & '\\' & '-' # [\\] ==> [\]
            if j+1 < len(tkstr)-e and tkstr[j+1] == '-': ccset = ccset + {tkstr[j]..tkstr[j+2]}; j = j + 3 # (elif ==> if)
            else: ccset = ccset + {tkstr[j]}; j = j + 1

          if tkstr[0] == '^': ccset = availchars - ccset
          if symbol in ccset: result[i] &= curconfig[i]; result[i] = deduplicate(result[i])
        else: discard # {initpos, accpos}
  # end of delta
  var config = einitconfig
  var l = 0 # current input position
  while l < len(x): 
    config = delta(config, x[l]) #; echo "delta config = ", config
    config = eclosure(config, follow) #; echo "eclos config = ", config # initial configuration (mark-before)
    inc(l)
  return config
# end of runonfrom
proc mrun_on(einitconfig: Config, xs: seq[string]): seq[Config] = # multiple runs on multiple input text strings  
  for x in xs: # runs on several text inputs
    result &= runonfrom(x, einitconfig, token, follow) # seq of lastConfigs
iterator mrun_on(einitconfig: Config, xs: seq[string]): (string, Config) = # iterated runs on multiple input text strings  
  for x in xs: # runs on several text inputs
    yield (x, runonfrom(x, einitconfig, token, follow)) # (x, lastConfig)

func toKinds*(fstseq: seq[tuple[froms: seq[string], to: string]]): Hashset[string] = # set of "string-string" 
  for (fs, t) in fstseq: 
    for f in fs: result.incl(f & "-" & t)
func avaiKinds*(iniset, accset: seq[int], token: Token): Hashset[string] = # set of "string-string" 
  for i in iniset:
    for a in accset: result.incl(token[i][1] & "-" & token[a][1]) #; echo "i,a = " & $i & " " & $a

when isMainModule: # display the result
  echo "reg exp = " & ptt #echo "reg exp = " & pttnum(ptt)
  let einitConfig = geteinitConfig(avaistates, iniset, token, follow) #; echo "einitConfig = ", einitConfig
  for x, lastconfig in mrun_on(einitconfig, xs): # needs accset & token to get kinds of acceptance
    let kinds = lastConfig.pairs.toSeq.filterIt(it[0] in accset and it[1] != @[]).mapIt((it[1], token[it[0]][1])).toKinds()
    let kindsseq = kinds.toSeq
    let kindsstr = if kindsseq == @[]: "None" else: kindsseq.foldl(a & ", " & b) # cannot fold @[] in case of Hashset
    echo "text x = \"", x, "\": accepting paths (from-to) = ", kindsstr
  let akindsseq = avaiKinds(iniset, accset, token).toSeq
  let akindsstr = if akindsseq == @[]: "None" else: akindsseq.foldl((a & ", " & b)) # cannot fold @[] in case of Hashset
  echo "available (ini, acc) color pairs = ", akindsstr
# X -> '[' (ε | '^')(ε | '-') Y* (ε | '-') ']' = '[' (ε | '^')(ε | '-')('a' | 'a-a')*(ε | '-') ']'
# Y -> 'a' + 'a-a'
#                           +<-----------+
#                           ↓ {a-}       ↑  {-}
# X ->○--- ^ --->○--- - --->○--- a-a --->◎--- - --->◎
#      \   {-,a}/ \     {a}/↓ {aa,a-,a]} ↑ \{]} or end
#       +----->○   +----->○ +---> a ---->◎ +------->◎
#[
>bicreMATCHER r":>^R[+-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B" "12.34" "-1.23" "1234" "+123" ".123" "123." "."
reg exp = :>^R[+-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B
text x = "12.34": accepting paths (from-to) = C-B
text x = "-1.23": accepting paths (from-to) = R-B
text x = "1234": accepting paths (from-to) = C-G
text x = "+123": accepting paths (from-to) = R-G
text x = ".123": accepting paths (from-to) = C-B
text x = "123.": accepting paths (from-to) = C-B
text x = ".": accepting paths (from-to) = None
available (ini, acc) color pairs = C-B, C-G, R-B, R-G
--------------------------------------------------------------------------------------------------------------------
reg exp = :>((0|(0|1<:_B0)(000<:_B0)*001)(<:_R1(0<:_G00<:_B0)*0<:_G01)*<:_R0)*(0|1<:_B0)(000<:_B0)*0<:_G
text x = "0": accepting paths (from-to) = -R
text x = "1": accepting paths (from-to) = -B
text x = "00": accepting paths (from-to) = -G
text x = "0000": accepting paths (from-to) = -G, -B
available (ini, acc) color pairs = -G, -B, -R
]#