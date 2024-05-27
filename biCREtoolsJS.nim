# nim js biCREtoolsJS.nim => biCREtoolsJS.js
import bicreMATCHER, tables, sequtils, sets # import bicrePARSERmodule and bicrePREPROrepeat indirectly throuth bicreMATCHER
import bicrePARSERdiagram, biCREtoRE
#template `=~`*(x: string, ptt: string): untyped = # to call `runonfrom`
#let x = "webmaster@example.com" #,r"a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-@a-zA-Z0-9.a-zA-Z0-9.a-zA-Z0-9","ab@cd-.ef"
#let ptt = r":>[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?<:\.)*"

var ptt2: string # for repeat expanded ptt
var follow = initTable[int, seq[int]]() # ex. follow[0] = @[1,2,3] #!!
var token = initTable[int, (Tokenkind, string)]() # ex. token[0] = (initpos, "") #!!!

proc getFollowstr(ptt: cstring): cstring {.exportc.} =
  ptt2 = expndrepeat($ptt)
  var fstr: string
  (follow, token) = biCREfollowtoken(ptt2)
  fstr = "final follow = " & $follow & "\p"
  fstr &= "final token = " & $token & "\p"
  fstr &= "regex string = "
  for i in 0..<len(ptt2):
    fstr &= "\"" & ptt2[i] & "\"[" & $i & "] "
  fstr &= "\p\p"
  return fstr # Warning: implicit conversion to 'cstring' from a non-const location

proc getPoseautostr(): cstring {.exportc.} = # the button disable = true until getFollowstr invoked
  result = biCREdotdiagram(ptt2)

proc getRunresultstr(x: cstring): cstring {.exportc.} = # the button disable = true until getFollowstr invoked
  let avaistates = getavaistates(follow)
  let (iniset, accset) = getinisetaccset(avaistates, token)
  let einitConfig = geteinitConfig(avaistates, iniset, token, follow)
  let lastConfig = runonfrom($x, einitConfig, token, follow)
  let kinds = lastConfig.pairs.toSeq.filterIt(it[0] in accset and it[1] != @[]).mapIt((it[1], token[it[0]][1])).toKinds()
  let kindsseq = kinds.toSeq
  let kindsstr = if kindsseq == @[]: "None" else: kindsseq.foldl(a & ", " & b) # cannot fold @[] in case of Hashset
  result = "accepting paths (from-to) = " & kindsstr & "\p\p"

proc getAllkindsstr():  cstring {.exportc.} = # the button disable = true until getFollowstr invoked
#  let KINDS = avaiKinds(iniset, accset, token)#.toSeq # implicitly declared and can be used in the scope of the call.
  let avaistates = getavaistates(follow)
  let (iniset, accset) = getinisetaccset(avaistates, token)
  let akindsseq = avaiKinds(iniset, accset, token).toSeq
  let akindsstr = if akindsseq == @[]: "None" else: akindsseq.foldl((a & ", " & b)) # cannot fold @[] in case of Hashset
  result = "available (ini, acc) color pairs = " & akindsstr & "\p\p"

proc getREstrs(ptt: cstring): cstring {.exportc.} = # the button disable = false from beginning
  let tkseqs = toREs($ptt)
  result = "decomposed expressions = \p"
  for i, tks in tkseqs: result &= $i & ": \"" & tks.toStr & "\"\p"
  result &= "\p"

