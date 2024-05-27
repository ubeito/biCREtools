#【両端色付き付き正規表現に対応する位置εオートマトンの遷移図出力 written by Akira Ito】
import bicrePARSERmodule, tables, sequtils, algorithm, parseopt
var ptt = r":>((a<:b)+c)*" #test2 not∋ca,∋abca # r":>((a<:b)*c)*" #test2 ∋ca ==> Fact2 of manuscript is "insufficient"
#var ptt = r":>^R[+\-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B" # r":>(0|1)*1(0|1)<:(0|1)<:" # r":>(0|1(<:_B01*<:_C0|11)*1<:_D0)*<:_A" # r":>([A-Z][a-z]*<: )*" # r":>(0:><:1)*<:" # r":>^00:>^10:>^201<:_41<:_51<:_6" # r"(a|:>b)*<:" # r"empty:><:string" 
#var ptt = r":>(a|[])(b|[])<:" # r":>a|<:"#={} # r":>(a|[])<:"#=a+ε # r":>a[]<:" #=aε # r":>[]<:" #=ε # for check of rule F -> [] addition
#var ptt = r":>.*<:" # r":>a?<:"#=a+empstr # r":>a*+<:" #:error # r":>|<:"#1={} # r":>(a|a)<:"#2=a+a # r":>(a|)<:"#:error # r":>(a||a)<:"#:error # r":>(|a)<:" #:error r":>(|)<:" #:error # for check of rule F -> [] addition
## r":>(0?0?<:1)*" # r":>1?(01)*0?<:" # r"(<:a:>)*" # r"(:>a<:)*" # r":><:?" # r":>?<:" # r":>*<:" # r":>+<:" # r"(:>a<:b)+" # r"(:>a<:b)(:>a<:b)*" # r"(:>a<:b)*" # r":>(a<:)+" # r":>(a<:)*(a<:)" # r":>(a<:)(a<:)*" # r":>(0<:|0)"
var p= initOptParser(ptt & @[]); p.next(); ptt = p.key # for command line execution

proc biCREdotdiagram*(biRE: string): string = # dot specification string of position epsilon-automaton constructed from CRE string
  let (follow, token) = biCREfollowtoken(biRE) # (Table[int, seq[int]], Table[int, (Tokenkind, string)]) #!!
  var spc = """ 
digraph position_epshilon_automaton {
ranksep=""" & $(token.len/10) & "\p" & # "1.2" // "3.0" for long complicated expressions
  """
node [shape=square] // default shape for ordinary characters
{rank=same;
"""
  let stseq = token.keys.toSeq.sorted # sorted index seq
  var c = 0 # for color index in graphviz color scheme 
  for i in stseq:
    case token[i][0]
    of avachar,chclass,escchar,dotany,empstr: spc &= $i & " [label=\"" & token[i][1] & "\"]\n" 
    of initpos:
      if token[i][1] == "":
        spc &= $i & " [label=\"" & token[i][1] & "\",shape=triangle,orientation=270,tailport=e]\n" ; inc(c)
      else:
        spc &= $i & " [label=\"" & token[i][1] & "\",shape=triangle,orientation=270,tailport=e,colorscheme=set312,style=filled,fillcolor=" & $(c.mod(12)+1) & "]\n" ; inc(c)
    of accpos:
      if token[i][1] == "":
        spc &= $i & " [label=\"" & token[i][1] & "\",shape=triangle,orientation=90,headport=w]\n" ; inc(c) 
      else:
        spc &= $i & " [label=\"" & token[i][1] & "\",shape=triangle,orientation=90,headport=w,colorscheme=set312,style=filled,fillcolor=" & $(c.mod(12)+1) & "]\n" ; inc(c) 
  spc &= "} // end of rank=same\n"
  for k,v in follow.pairs:
    spc &= $k & " -> {" & foldl(v.mapit($it), a & "," & b) & "} [headport=w,tailport=e]\n"
  spc &= "edge [style=\"invis\"]\n"
  spc &= foldl(stseq.mapit($it), a & " -> " & b)
  spc &= "\n} // end of digraph"
  return spc
when isMainModule: 
  let spc = biCREdotdiagram(ptt); echo spc
  # write dot file
  let gvname = "biCREdiagram" # "biCREtobiCFA"
  let f : File = open(gvname & ".gv", FileMode.fmWrite)
  #defer: close(f) # Error: defer statement not supported at top level
  try:
    f.writeLine spc
  finally:
    close(f)
  # print png file
  import osproc
  discard execCmd("dot -Tpng -Gdpi=200 " & gvname & ".gv -o" & gvname & ".png")
  when defined(windows): discard execCmd("mspaint " & gvname & ".png")
#[
>bicrePARSERdiagram r":>^R[+\-]:>^C[0-9]*(\.[0-9]|[0-9]<:_G\.)[0-9]*<:_B"
digraph position_epshilon_automaton {
ranksep=1.6
node [shape=square] // default shape for ordinary characters
{rank=same;
0 [label="R",shape=triangle,orientation=270,tailport=e,colorscheme=set312,style=filled,fillcolor=1]
4 [label="+\-"]
9 [label="C",shape=triangle,orientation=270,tailport=e,colorscheme=set312,style=filled,fillcolor=2]
13 [label="0-9"]
18 [label="*"]
19 [label="("]
20 [label="."]
22 [label="0-9"]
27 [label="|"]
28 [label="0-9"]
33 [label="G",shape=triangle,orientation=90,headport=w,colorscheme=set312,style=filled,fillcolor=3]
37 [label="."]
39 [label=")"]
40 [label="0-9"]
45 [label="*"]
46 [label="B",shape=triangle,orientation=90,headport=w,colorscheme=set312,style=filled,fillcolor=4]
} // end of rank=same
20 -> {22} [headport=w,tailport=e]
4 -> {13,20,28} [headport=w,tailport=e]
9 -> {13,20,28} [headport=w,tailport=e]
37 -> {40,46} [headport=w,tailport=e]
22 -> {40,46} [headport=w,tailport=e]
0 -> {4} [headport=w,tailport=e]
28 -> {33,37} [headport=w,tailport=e]
40 -> {40,46} [headport=w,tailport=e]
13 -> {13,20,28} [headport=w,tailport=e]
edge [style="invis"]
0 -> 4 -> 9 -> 13 -> 18 -> 19 -> 20 -> 22 -> 27 -> 28 -> 33 -> 37 -> 39 -> 40 -> 45 -> 46
} // end of digraph
]#
