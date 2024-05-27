#【両端色付き付き正規表現のfollow関数＆トークン列を求めるモジュール written by Akira Ito】
import sequtils, tables
type NullFirstLast* = tuple[nullable: bool, first: seq[int], last: seq[int]] #!!
const availChars* = {' '..'~'} # == " !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~"
const reservChars* = {'*','+','.','?','(',')','[',']','|','\"','\\'} #; const reservStrs* = @[":>",":>^","<:","<:_"] + @['\' & reservChars] 
type Tokenkind* = enum avachar, initpos, accpos, chclass, escchar, dotany, empstr #!4
proc biCREfollowtoken*(biRE: string): (Table[int, seq[int]], Table[int, (Tokenkind, string)]) = # = (follow function, token function)
  let ptt = biRE & "$"
  var i = 0 # position index of regex string
  var follow = initTable[int, seq[int]]() # ex. follow[0] = @[1,2,3] #!!
  var token = initTable[int, (Tokenkind, string)]() # ex. token[0] = (initpos, "") #!!!
  # Unix風正規表現記法を表す両端付き拡張文脈自由文法 E' -> E$, 
  # E -> :>1{ ( :>2{ :>3( '(' E ')'<:31 + 'a'<:32 + '<:'<:33 + ':>'<:34 )( '*'<:35 + '?'<:36)<:2 }*<:1 '|' }*
  # に対する再帰下降型構文解析器
  proc E() : NullFirstLast = #!!
    result = (false, @[], @[]) # initial value of helperAl (left child) of Addition (plus) node #!!
    var cA: int = 0 # cA = 1,2... index of children of plus node #!!
    var helperAr: NullFirstLast # = (true, @[], @[]) # initial value of helperPl (left child) of Product (concat) node #!!
    while (true): # :>1
      helperAr = (true, @[], @[]) #!!
      inc(cA) #!!
      var cP: int = 0 # cP = 1,2,... index of children of concat node #!!
      var helperPr: NullFirstLast # = (true, @[], @[]) # current right child of Product (concat) node #!!
      while (true): ## :>2
        let i0 = i # starting position index of token
        helperPr = (true, @[], @[]) # (not required) #!!
        inc(cP) #!!
        if ptt[i] == '(': ### :>3 
          token[i] = (avachar, "(") #!!!
          inc(i); helperPr = E() #!!
          if ptt[i] != ')': raise newException(IOError, "NOT ')'")
          else: ### <:31
            token[i] = (avachar, ")") #!!!
            inc(i)
        elif ptt[i] in availChars - reservChars + {'[','\\','.'} - {':','<'}: # ptt[i] == 'a': ### <:32
          helperPr = (false,@[i],@[i]) #!!
          if ptt[i] == '[':
            i += ptt[i..^1].find(']') 
            if i == i0 + 1: token[i0] = (empstr, "[]"); helperPr = (true, @[], @[]) #!4
            else: token[i0] = (chclass, ptt[i0+1..<i]) # i0 = i;  # skip '[...]' for char class
          elif ptt[i] == '\\': token[i] = (escchar, $ptt[i+1]); inc(i) # skip one char for escape seq
          elif ptt[i] == '.': token[i] = (dotany, ".") #; discard # match any single char
          else: token[i] = (avachar,$ptt[i])
          inc(i)
        elif ptt[i] == ':':
          if ptt[i+1] == '>': # init state pos symbol ### <:33
            helperPr = (true,@[],@[i]) #; i0 = i #!!
            inc(i); inc(i)
            if ptt[i] == '^': token[i0] = (initpos, $ptt[i0+3]); inc(i); inc(i) # with additional one char label
            else: token[i0] = (initpos, "")
          else: # ':' is not init state pos symbol (an ordinary char ### <:32)
            token[i] = (avachar, ":") #!!!
            helperPr = (false,@[i],@[i]) #!!!
            inc(i) #!!
        elif ptt[i] == '<':
          if ptt[i+1] == ':': # acc state pos symbol ### <:34
            helperPr = (true,@[i],@[]) #; i0 = i #!!!
            inc(i); inc(i)
            if ptt[i] == '_': token[i0] = (accpos, $ptt[i0+3]); inc(i); inc(i) # with additional one char label
            else: token[i0] = (accpos, "")
          else: # '<' is not acc state pos symbol (an ordinary char ### <:32)
            token[i] = (avachar, "<") #!!!
            helperPr = (false,@[i],@[i]) #!!!
            inc(i) #!!
        else: raise newException(IOError, "NOT '(','a','[','\\','.','<',':'") # ptt[i] != '(' and ptt[i] != 'a' and ...
        if ptt[i] == '*' or ptt[i] == '+': ### <:35
          token[i] = if ptt[i] == '*': (avachar, "*") else: (avachar, "+") #!!!
          helperPr.nullable = if ptt[i] == '*': true else: false ## fist[v] = fist[child]; last[v] = last[child]; #!!
          for x in helperPr.last: # for each last element of the child of star node: #!!
            if not follow.hasKey(x): follow[x] = @[] #!!
            follow[x] &= helperPr.first # culminating union of first elements of the child of P node to follow(x) #!!
            follow[x] = deduplicate(follow[x]) # not necessarily disjoint! #!!
          inc(i)
        if ptt[i] == '?': ### <:36
          token[i] = (avachar, "?") #!!!
          helperPr.nullable = true; ## fist[v] = fist[child]; last[v] = last[child]; #!!
          inc(i)
        for x in helperAr.last: # for each last element of left child of P node: #!!
          if not follow.hasKey(x): follow[x] = @[] #!!
          follow[x] &= helperPr.first # culminating union of first elements of right child of P node to follow(x) #!!
        if helperAr.nullable: helperAr.first &= helperPr.first # else helperAr.first not change #!!
        if helperPr.nullable: helperAr.last &= helperPr.last else: helperAr.last = helperPr.last  #!!
        helperAr.nullable = helperAr.nullable and helperPr.nullable # culminating AND of all children of P node #!!
        if ptt[i] == '|' or ptt[i] == '$' or ptt[i] == ')': # ※ one charactor look-ahead
          break ## <:2  (concat)
      # end of concat operators
      result.nullable = result.nullable or helperAr.nullable # culminating OR of all children of A node #!!
      result.first &= helperAr.first # culminating union of all children of A node #!!
      result.last &= helperAr.last # culminating union of all children of A node #!!
      # end of + operators
      if ptt[i] != '|':
        break # <:1
      token[i] = (avachar,"|") #!!!
      inc(i) # and repeat when ptt[i] == '|'
    return result
  # end of E()
  discard E()
  if ptt[i] != '$': raise newException(IOError, "NOT '$'")
  return (follow, token)
# end of biCREfollow()
when isMainModule: 
  var ptt = r":>^R[+-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B" # r":>(0|1)*1(0|1)<:(0|1)<:" # r":>(0|1(<:_B01*<:_C0|11)*1<:_D0)*<:_A" # r":>(0?0?<:1)*" # r":>1?(01)*0?<:" # r"(a|:>b)*<:" # r":>([A-Z][a-z]*<: )*" # r":>(0:><:1)*<:" #
  # r":>^R[+\-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B" # r":>(0|1)*1(0|1)<:(0|1)<:" # r":>(0|1(<:_B01*<:_C0|11)*1<:_D0)*<:_A" # r":>(0?0?<:1)*" # r":>1?(01)*0?<:" # r"(a|:>b)*<:" # r":>([A-Z][a-z]*<: )*" # r":>(0:><:1)*<:" #
  # r":>.*<:" # r":>a*+<:" #:error # r":>|<:"#1={} # r":>(a|a)<:"#2=a+a # r":>(a|)<:"#3={a} # r":>(a||a)<:"#=a+a # r":>(|a)<:" # r":>(|)<:" #:notaccept (error) # for check of rule E -> ε (<:12) addition
  # r":>.*<:" # r":>a*+<:" #:error # r":>|<:" # r":>(a|a)<:" # r":>(a|)<:" # r":>(a||a)<:" # r":>(|a)<:" # r":>(|)<:" #:notaccept # for check of rule E -> ε (<:12) addition
  # r":>(0<:|0)": bugfixed # r":>[abc]<:" # r":>\|<:" # r":>a|a<:" # r":>a*<:" # r":>a+<:" # r":>a|<:"#={}
  # r":><:" # r":>a<:" # r":>^Aa<:" # r":>a<:_B" # r":>^Aa<:_B" # r"(a)" # r"a" # r":>(a)<:" # r":>(a|a)<:" # r"(:>^Aa)<:" # r":>\.<:" # r":>(a|b|c)<:" # 
  echo "final follow = ", biCREfollowtoken(ptt)[0] #!!
  echo "final token = ", biCREfollowtoken(ptt)[1] #!!!
  var pttnum = "regex string = "; for i in 0..<len(ptt): pttnum &= "\"" & ptt[i] & "\"[" & $i & "] "  #!!
  echo pttnum #!!
######################################################################################################################
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
######################################################################################################################
#               ｜ result 
#               ＋ == (helperA) 
# == (helperAl) /\ helperAr
#              △ ・ == (helperP)
#                 /\
#  == (helperPl) △ ○ helperPr
######################################################################################################################
#final follow = {5: @[3, 5, 8], 3: @[3, 5, 8], 17: @[21], 19: @[21], 10: @[14, 17, 19], 0: @[3, 5, 8], 12: @[14, 17, 19], 8: @[10, 12]}
#final token = {20: (avachar, ")"), 14: (accpos, ""), 4: (avachar, "|"), 9: (avachar, "("), 5: (avachar, "1"), 7: (avachar, "*"), 11: (avachar, "|"), 3: (avachar, "0"), 2: (avachar, "("), 17: (avachar, "0"), 18: (avachar, "|"), 19: (avachar, "1"), 16: (avachar, "("), 6: (avachar, ")"), 10: (avachar, "0"), 0: (initpos, ""), 12: (avachar, "1"), 21: (accpos, ""), 8: (avachar, "1"), 13: (avachar, ")")}
#regex string = ":"[0] ">"[1] "("[2] "0"[3] "|"[4] "1"[5] ")"[6] "*"[7] "1"[8] "("[9] "0"[10] "|"[11] "1"[12] ")"[13] "<"[14] ":"[15] "("[16] "0"[17] "|"[18] "1"[19] ")"[20] "<"[21] ":"[22] 
