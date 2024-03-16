#【両端色付き正規表現をサポートする純粋ライブラリー written by Akira Ito】
import bicreMATCHER, tables, sequtils, sets # import bicrePARSERmodule and bicrePREPROrepeat indirectly throuth bicreMATCHER
export bicreMATCHER # for usage as lib in other apps
export sequtils.toSeq, sequtils.filterIt, sequtils.mapIt, sets #.contains # for Hashset
template `=~`*(x: string, ptt: string): untyped = # to call `runonfrom`
  let ptt2 = expndrepeat(ptt)
  let (follow, token) = biCREfollowtoken(ptt2)
  let avaistates = getavaistates(follow)
  let (iniset, accset) = getinisetaccset(avaistates, token)
  let einitConfig = geteinitConfig(avaistates, iniset, token, follow)
  let lastConfig = runonfrom(x, einitConfig, token, follow)
  let kinds {.inject.} = lastConfig.pairs.toSeq.filterIt(it[0] in accset and it[1] != @[]).mapIt((it[1], token[it[0]][1])).toKinds()
  let KINDS {.inject.} = avaiKinds(iniset, accset, token)#.toSeq # implicitly declared and can be used in the scope of the call.
  kinds.len != 0

runnableExamples:
  for line in @["webmaster@example.com",r"a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-@a-zA-Z0-9.a-zA-Z0-9.a-zA-Z0-9","ab@cd-.ef"]:
    echo "[text = \"" & line & "\"]:"
    if line =~ r":>[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?<:\.)*":
      echo "valid email address in HTML Living Standard"
    else: echo "invalid email address"
#[
[text = "webmaster@example.com"]:
valid email address in HTML Living Standard
[text = "a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-@a-zA-Z0-9.a-zA-Z0-9.a-zA-Z0-9"]:
valid email address in HTML Living Standard
[text = "ab@cd-.ef"]:
invalid email address
]#