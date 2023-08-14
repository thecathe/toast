
@test !evaluate(Clocks([("a",1)]),Eq("a",2))
@test evaluate(Clocks([("a",3)]),Geq("a",2))
@test evaluate(Clocks([("a",3)]),Not(Geq("b",2)))