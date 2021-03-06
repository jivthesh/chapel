class IfInit {
  param f1: bool;
  param f2: int;

  proc init(param val: int) {
    f1 = val > 10;
    // Verifies that if statements can be used in Phase 1 of an initializer
    if (f1) {
      f2 = 10;
    } else {
      f2 = val;
    }
  }
}

proc main() {
  var c = new IfInit(12);
  writeln(c.type: string);
  delete c;
}
