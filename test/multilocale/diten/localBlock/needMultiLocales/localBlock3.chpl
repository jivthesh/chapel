class C {
  var a: int;
  var b: real;
}

def main {
  var c = new C(1, 1.0);
  var A: [1..5] int;
  on Locales(1) {
    c = new C(2, 2.0);
  }

  local {
    A = foo(c);
  }
  writeln(A);
}

def foo(c: C) {
  for i in 1..5 {
    yield bar(c) + i;
  }
}

def bar(c: C) {
  var ret = c.a + 1; // error, c.a is remote
  return ret;
}
