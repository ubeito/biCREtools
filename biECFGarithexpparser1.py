def E():
  global i
  exp = 0
  while (True):   # :>^1
    term = 1
    while (True):   # :>^2
      if inp[i] == '[':   # :>^3
        i += 1; factor = E()
        if inp[i] != ']': raise Exception("NOT ']'")
      elif not inp[i].isdigit(): raise Exception("NOT a digit")
      else: factor = int(inp[i])
      term = term * factor   # <:_3
      i += 1
      if inp[i] != '*': break   # <:_2
      i += 1 # else: inp[i] == '*'
    exp = exp + term
    if inp[i] != '+': break   # <:_1
    i += 1 # else: inp[i] == '+'
  return exp
while (True):
  i = 0
  inp = input("expression or q >>") + "$"
  if inp == "q$": break
  print(E())
  if inp[i] != '$': raise Exception("NOT '$'")
"""
expression or q >>1+2
3
expression or q >>1+2*3
7
expression or q >>[1+2]*3
9
expression or q >>3+[2*1+2*[3+1]]*2+[3]
26
expression or q >>q
"""