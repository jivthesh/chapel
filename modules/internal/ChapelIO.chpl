/*
 * Copyright 2004-2016 Cray Inc.
 * Other additional copyright holders may be indicated within.
 * 
 * The entirety of this work is licensed under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * 
 * You may obtain a copy of the License at
 * 
 *     http://www.apache.org/licenses/LICENSE-2.0
 * 
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*

Basic types and utilities in support of I/O operation.
 
Most of Chapel's I/O support is within the :mod:`IO` module.
This automatically included module provides several basic
types and routines that support the :mod:`IO` module.
 
Writing and Reading
~~~~~~~~~~~~~~~~~~~

The :proc:`~IO.writeln` function allows for a simple implementation
of a Hello World program:

.. code-block:: chapel

 writeln("Hello, World!");
 // outputs
 // Hello, World!

The :proc:`~IO.read` functions allow one to read values into variables as
the following example demonstrates. It shows three ways to read values into
a pair of variables ``x`` and ``y``.

.. code-block:: chapel

  var x: int;
  var y: real;

  /* reading into variable expressions, returning
     true if the values were read, false on EOF */
  var ok:bool = read(x, y);

  /* reading via a single type argument */
  x = read(int);
  y = read(real);

  /* reading via multiple type arguments */
  (x, y) = read(int, real);

The write method on strings
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The ``write`` method can also be called on strings to write the output to a
string instead of a channel. The string will be appended to.

The readThis(), writeThis(), and readWriteThis() Methods
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

When programming the input and output method for a custom data type, it is
often useful to define both the read and write routines at the same time. That
is possible to do in a Chapel program by defining a ``readWriteThis`` method,
which is a generic method expecting a single argument: either a Reader or a
Writer.

In cases when the reading routine and the writing routine are more naturally
separate, or in which only one should be defined, a Chapel program can define
``readThis`` (taking in a single argument of type Reader) and/or
``writeThis`` (taking in a single argument of type Writer).

If none of these routines are provided, a default version of ``readThis`` and
``writeThis`` will be generated by the compiler. If ``readWriteThis`` is
defined, the compiler will generate ``readThis`` or ``writeThis`` methods - if
they do not already exist - which call ``readWriteThis``.

Objects of type :class:`Reader` or :class:`Writer` both support the following
fields and methods:

 * :attr:`Reader.writing`, :attr:`Writer.writing` return `true` if called on a
   :class:``Writer`` and `false` if called on a :class:``Reader``.
 * :attr:`Reader.binary`, :attr:`Writer.binary` return `true` if called on a
   Reader or Writer that is configured to perform binary I/O, and `false`
   otherwise.
 * :proc:`Reader.error`, :proc:`Writer.error` return a saved error code.
 * :proc:`Reader.setError`, :proc:`Writer.setError` save an error code.
 * :proc:`Reader.clearError`, :proc:`Writer.clearError` clear any saved error
   code.
 * :proc:`Reader.readwrite`, :proc:`Writer.readwrite` read or write a value
   according to its readThis or writeThis method.
 * :proc:`Reader.readWriteLiteral`, :proc:`Writer.readWriteLiteral` read or
   write a literal string value.
 * :proc:`Reader.readWriteNewline`, :proc:`Writer.readWriteNewline` read and
   discards input until a newline or writes a newline.

Objects of type :class:`Reader` also supports the following methods:

 * :proc:`Reader.read` (similar to :proc:`IO.channel.read`)
 * :proc:`Reader.readln` (similar to :proc:`IO.channel.readln`)

Objects of type :class:`Writer` also support the following methods:

 * :proc:`Writer.write` (similar to :proc:`IO.channel.read`)
 * :proc:`Writer.writeln` (similar to :proc:`IO.channel.writeln`)

Note that objects of type :class:`Reader` or :class:`Writer` may represent a
locked channel; as a result, using parallelism constructs to call methods on
:class:`Reader` or :class:`Writer` may result in undefined behavior.

.. note::

  In the future, we plan to merge :class:`Reader`, :class:`Writer`, and
  :record:`IO.channel` in order to support calling :proc:`IO.channel.readf`
  and other I/O routines inside a ``readThis`` method.

Because it is often more convenient to use an operator for I/O, instead of
writing

.. code-block:: chapel

  f.readwrite(x);
  f.readwrite(y);

one can write

.. code-block:: chapel

  f <~> x <~> y;

Note that the types :type:`IO.ioLiteral` and :type:`IO.ioNewline` may be useful
when using the ``<~>`` operator. :type:`IO.ioLiteral` represents some string
that must be read or written as-is (e.g. ``","`` when working with a tuple),
and :type:`IO.ioNewline` will emit a newline when writing but skip to and
consume a newline when reading.


This example defines a readWriteThis method and demonstrates how ``<~>`` will
call the read or write routine, depending on the situation.

.. code-block:: chapel

  class IntPair {
    var x: int;
    var y: int;
    proc readWriteThis(f) {
      f <~> x <~> new ioLiteral(",") <~> y <~> new ioNewline();
    }
  }
  var ip = new IntPair(17,2);
  write(ip);
  // prints out
  // 17,2

  delete ip;

This example defines a only a writeThis method - so that there will be a
function resolution error if the class NoRead is read.

.. code-block:: chapel

  class NoRead {
    var x: int;
    var y: int;
    proc writeThis(f:Writer) {
      f.writeln("hello");
    }
    // Note that no readThis function will be generated.
  }
  var nr = new NoRead();
  write(nr);
  // prints out
  // hello

  // Note that read(nr) will generate a compiler error.

  delete nr;


Generalized write and writeln
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The :class:`Writer` class contains no fields and serves as a base class to
allow user-defined classes to be written to.  If a class is defined to be a
subclass of Writer, it must override the :class:`Writer.writePrimitive` method
with any Chapel primitive type as an argument.

The following code defines a subclass of :class:`Writer` that overrides the
:proc:`Writer.writePrimitive` method to allow it to be written to.  It also
overrides the ``writeThis`` method to override the default way that it is
written.

.. code-block:: chapel

  // A demonstration writer class that filters
  // values printed to it by only printing the first
  // character.
  class C: Writer {
    // A variable to accumulate some writes.
    var data: string;

    // writePrimitive will be called when
    // c.write(...) is called
    proc writePrimitive(x) {
      var s = x:string;
      // only save the first letter
      data += s[1];
    }

    // writeThis will be called when
    // e.g. stdout.write(c) is called
    proc writeThis(x: Writer) {
      x.write(data);
    }
  }

  var c = new C();
  // c.write will invoke c.writePrimitive
  // with each numeric value in turn
  c.write(41, 32, 23, 14);
  // writeln is stdout.writeln and will invoke
  // c.writeThis.
  writeln(c);
  // prints out:
  // 4321

  delete c;


.. _default-write-and-read-methods:

Default write and read Methods
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Default ``write`` methods are created for all types for which a user-defined
``write`` method is not provided.  They have the following semantics:

* for an array argument: outputs the elements of the array in row-major order
  where rows are separated by line-feeds and blank lines are used to separate
  other dimensions.
* for a `domain` argument: outputs the dimensions of the domain enclosed by
  ``[`` and ``]``.
* for a `range` argument: output the lower bound of the range, output ``..``,
  then output the upper bound of the range.  If the stride of the range
  is not ``1``, output the word ``by`` and then the stride of the range.
* for a tuples, outputs the components of the tuple in order delimited by ``(``
  and ``)``, and separated by commas.
* for a class: outputs the values within the fields of the class prefixed by
  the name of the field and the character ``=``.  Each field is separated by a
  comma.  The output is delimited by ``{`` and ``}``.
* for a record: outputs the values within the fields of the class prefixed by
  the name of the field and the character ``=``.  Each field is separated by a
  comma.  The output is delimited by ``(`` and ``)``.

Default ``read`` methods are created for all types for which a user-defined
``read`` method is not provided.  The default ``read`` methods are defined to
read in the output of the default ``write`` method.

.. note::

  Note that it is not currently possible to read and write circular
  data structures with these mechanisms.

 */
module ChapelIO {
  use ChapelBase; // for uint().
  use SysBasic;
  // use IO; happens below once we need it.
  
  // TODO -- this should probably be private
  pragma "no doc"
  proc _isNilObject(val) {
    proc helper(o: object) return o == nil;
    proc helper(o)         return false;
    return helper(val);
  }
  
  /*
     An abstract base class type for classes that know how
     to write values.
   */
  class Writer {
    /* returns `true` */
    proc writing param return true;
    /* returns `true` if this Writer is configured for binary I/O. */
    proc binary():bool { return false; }
    /* return other style elements.
       subclasses should override this method */
    pragma "no doc"
    proc styleElement(element:int):int { return 0; }

    /* 
       Return any saved error code.
       Subclasses should override this method.
     */
    proc error():syserr { return ENOERR; }
    /*
       Save an error code.
       Subclasses should override this method.
     */
    proc setError(e:syserr) { }
    /* 
       Clear any saved error code.
       Subclasses should override this method.
     */
    proc clearError() { }
    /* Write a primitive type.
       Subclasses should override this method.
     */
    proc writePrimitive(x) {
      //compilerError("Generic Writer.writePrimitive called");
      halt("Generic Writer.writePrimitive called");
    }
    /*
       Write a sequence of bytes.
       Subclasses should override this method.
     */
    pragma "no doc"
    proc writeBytes(x, len:ssize_t) {
      halt("Generic Writer.writeBytes called");
    }
    pragma "no doc"
    proc writeIt(x:?t) {
      if _isIoPrimitiveTypeOrNewline(t) {
        writePrimitive(x);
      } else {
        if isClassType(t) || chpl_isDdata(t) {
          // FUTURE -- write the class name/ID?
  
          if x == nil {
            var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
            var iolit:ioLiteral;
            if st == QIO_AGGREGATE_FORMAT_JSON {
              iolit = new ioLiteral("null", !binary());
            } else {
              iolit = new ioLiteral("nil", !binary());
            }
            writePrimitive(iolit);
            return;
          }
        }
  
        x.writeThis(this);
      }
    }
    /*
       Write anything by calling writeThis methods
       or by using writePrimitive. Subclasses should
       not need to override this method.
     */
    proc readwrite(x) {
      writeIt(x);
    }
    /* 
       Write anything by calling writeThis methods
       or by using writePrimitive. Subclasses should
       not need to override this method.
     */
    proc write(args ...?k) {
      for param i in 1..k {
        writeIt(args(i));
      }
    }
    /*
       Write anything by calling writeThis methods
       or by using writePrimitive. Then write a newline
       character. Subclasses should not need to override this method.
     */
    proc writeln(args ...?k) {
      for param i in 1..k {
        writeIt(args(i));
      }
      var nl = new ioNewline();
      writeIt(nl);
    }
    /* 
       Write a newline character.
       Subclasses should not need to override this method.
     */
    proc writeln() {
      var nl = new ioNewline();
      writeIt(nl);
    }
    pragma "no doc"
    proc writeThisFieldsDefaultImpl(x:?t, inout first:bool) {
      param num_fields = __primitive("num fields", t);
      var isBinary = binary();
  
      if (isClassType(t)) {
        if t != object {
          // only write parent fields for subclasses of object
          // since object has no .super field.
          writeThisFieldsDefaultImpl(x.super, first);
        }
      }
  
      if !isUnionType(t) {
        // print out all fields for classes and records
        for param i in 1..num_fields {

          if isType(__primitive("field value by num", x, i)) ||
             isParam(__primitive("field value by num", x, i)) {
             // do nothing, don't output types or params
          } else {
            if !isBinary {
              var comma = new ioLiteral(", ");
              if !first then write(comma);
    
              var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
              var eq:ioLiteral;
              if st == QIO_AGGREGATE_FORMAT_JSON {
                eq = new ioLiteral(__primitive("field num to name", t, i) + c" : ");
              } else {
                eq = new ioLiteral(__primitive("field num to name", t, i) + c" = ");
              }
              write(eq);
            }
    
            write(__primitive("field value by num", x, i));
  
            first = false;
          }
        }
      } else {
        // Handle unions.
        // print out just the set field for a union.
        var id = __primitive("get_union_id", x);
        for param i in 1..num_fields {
          if __primitive("field id by num", t, i) == id {
            if isBinary {
              // store the union ID
              write(id);
            } else {
              var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
              var eq:ioLiteral;
              if st == QIO_AGGREGATE_FORMAT_JSON {
                eq = new ioLiteral(__primitive("field num to name", t, i) + c" : ");
              } else {
                eq = new ioLiteral(__primitive("field num to name", t, i) + c" = ");
              }
              write(eq);
            }
            write(__primitive("field value by num", x, i));
          }
        }
      }
    }
    // Note; this is not a multi-method and so must be called
    // with the appropriate *concrete* type of x; that's what
    // happens now with buildDefaultWriteFunction
    // since it has the concrete type and then calls this method.
  
    // MPF: We would like to entirely write the default writeThis
    // method in Chapel, but that seems to be a bit of a challenge
    // right now and I'm having trouble with scoping/modules.
    // So I'll go back to writeThis being generated by the
    // compiler.... the writeThis generated by the compiler
    // calls writeThisDefaultImpl.
    pragma "no doc"
    proc writeThisDefaultImpl(x:?t) {
      if !binary() {
        var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
        var start:ioLiteral;
        if st == QIO_AGGREGATE_FORMAT_JSON {
          start = new ioLiteral("{");
        } else if st == QIO_AGGREGATE_FORMAT_CHPL {
          start = new ioLiteral("new " + t:string + "(");
        } else {
          // the default 'braces' type
          if isClassType(t) {
            start = new ioLiteral("{");
          } else {
            start = new ioLiteral("(");
          }
        }
        write(start);
      }
  
      var first = true;
  
      writeThisFieldsDefaultImpl(x, first);
  
      if !binary() {
        var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
        var end:ioLiteral;
        if st == QIO_AGGREGATE_FORMAT_JSON {
          end = new ioLiteral("}");
        } else if st == QIO_AGGREGATE_FORMAT_CHPL {
          end = new ioLiteral(")");
        } else {
          if isClassType(t) {
            end = new ioLiteral("}");
          } else {
            end = new ioLiteral(")");
          }
        }
        write(end);
      }
    }
  }


  /*
     An abstract base class type for classes that know how
     to read values.
   */
  class Reader {
    /* returns `false` */
    proc writing param return false;
    /* returns `true` if this Reader is configured for binary I/O. */
    proc binary():bool { return false; }
    /* return other style elements.
       subclasses should override this method */
    pragma "no doc"
    proc styleElement(element:int):int { return 0; }

    /* 
       Return any saved error code.
       Subclasses should override this method.
     */
    proc error():syserr { return ENOERR; }
    /*
       Save an error code.
       Subclasses should override this method.
     */
    proc setError(e:syserr) { }
    /* 
       Clear any saved error code.
       Subclasses should override this method.
     */
    proc clearError() { }
  
    /* Read a primitive type.
       Subclasses should override this method.
     */
    proc readPrimitive(ref x:?t) where _isIoPrimitiveTypeOrNewline(t) {
      //compilerError("Generic Reader.readPrimitive called");
      halt("Generic Reader.readPrimitive called");
    }
    
    /*
       Read a sequence of bytes.
       Subclasses should override this method.
     */
    pragma "no doc"
    proc readBytes(x, len:ssize_t) {
      halt("Generic Reader.readBytes called");
    }
    pragma "no doc"
    proc readIt(x:?t) where isClassType(t) {
      // FUTURE -- write the class name/ID? or nil?
      // possibly in a different 'Reader'
      /*
      var iolit = new ioLiteral("nil", !binary());
      readPrimitive(iolit);
      if !(error()) {
        // Return nil.
        delete x;
        x = nil;
        return;
      } else {
        clearError();
      }*/
      x.readThis(this);
    }
    pragma "no doc"
    proc readIt(ref x:?t) where !isClassType(t) {
      if _isIoPrimitiveTypeOrNewline(t) {
        readPrimitive(x);
      } else {
        x.readThis(this);
      }
    }
    /*
       Read anything by calling readThis methods
       or by using readPrimitive. Subclasses should
       not need to override this method.
     */
    proc readwrite(ref x) {
      readIt(x);
    }
    /*
       Read anything by calling readThis methods
       or by using readPrimitive. Subclasses should
       not need to override this method.
     */
    proc read(ref args ...?k):bool {
      for param i in 1..k {
        readIt(args(i));
      }
  
      if error() {
        return false;
      } else {
        return true;
      }
    }
    /*
       Read anything by calling readThis methods
       or by using readPrimitive. Then read and discard
       any input until a newline
       character is reached. Subclasses should
       not need to override this method.
     */
    proc readln(ref args ...?k):bool {
      for param i in 1..k {
        readIt(args(i));
      }
      var nl = new ioNewline();
      readIt(nl);
      if error() {
        return false;
      } else {
        return true;
      }
    }
    /* 
       Read and discard any input until a newline character is reached.
       Subclasses should not need to override this method.
     */
    proc readln():bool {
      var nl = new ioNewline();
      readIt(nl);
      if error()  {
        return false;
      } else {
        return true;
      }
    }
    pragma "no doc"
    proc readThisFieldsDefaultImpl(type t, ref x, inout first:bool) {
      param num_fields = __primitive("num fields", t);
      var isBinary = binary();
  
      //writeln("Scanning fields for ", t:string);
  
      if (isClassType(t)) {
        if t != object {
          // only write parent fields for subclasses of object
          // since object has no .super field.
          readThisFieldsDefaultImpl(x.super.type, x, first);
        }
      }
  
      if !isUnionType(t) {
        // read all fields for classes and records
  
        for param i in 1..num_fields {
          
          if isType(__primitive("field value by num", x, i)) ||
             isParam(__primitive("field value by num", x, i)) {
             // do nothing, don't read types or params
          } else {
            if !isBinary {
              var comma = new ioLiteral(",", true);
              if !first then readIt(comma);
    
              var fname = new ioLiteral(__primitive("field num to name", t, i), true);
              readIt(fname);
    
              var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
              var eq:ioLiteral;
              if st == QIO_AGGREGATE_FORMAT_JSON {
                eq = new ioLiteral(":", true);
              } else {
                eq = new ioLiteral("=", true);
              }
              readIt(eq);
            }
    
            readIt(__primitive("field value by num", x, i));
    
            first = false;
          }
        }
      } else {
        // Handle unions.
        if isBinary {
          var id = __primitive("get_union_id", x);
          // Read the ID
          readIt(id);
          for param i in 1..num_fields {
            if __primitive("field id by num", t, i) == id {
              readIt(__primitive("field value by num", x, i));
            }
          }
        } else {
          // Read the field name = part until we get one that worked.
          for param i in 1..num_fields {
            var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
            var eq:ioLiteral;
            if st == QIO_AGGREGATE_FORMAT_JSON {
              eq = new ioLiteral(__primitive("field num to name", t, i) + " : ");
            } else {
              eq = new ioLiteral(__primitive("field num to name", t, i) + " = ");
            }

            readIt(eq);
            if error() == EFORMAT {
              clearError();
            } else {
              // We read the 'name = ', so now read the value!
              readIt(__primitive("field value by num", x, i));
            }
          }
        }
      }
    }
    // Note; this is not a multi-method and so must be called
    // with the appropriate *concrete* type of x; that's what
    // happens now with buildDefaultWriteFunction
    // since it has the concrete type and then calls this method.
    pragma "no doc"
    proc readThisDefaultImpl(x:?t) where isClassType(t) {
      if !binary() {
        var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
        var start:ioLiteral;
        if st == QIO_AGGREGATE_FORMAT_CHPL {
          start = new ioLiteral("new " + t:string + "(");
        } else {
          // json and braces type
          start = new ioLiteral("{");
        }
        readIt(start);
      }
  
      var first = true;
  
      var obj = x; // make obj point to x so ref works
      readThisFieldsDefaultImpl(t, obj, first);
  
      if !binary() {
        var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
        var end:ioLiteral;
        if st == QIO_AGGREGATE_FORMAT_CHPL {
          end = new ioLiteral(")");
        } else {
          // json and braces type
          end = new ioLiteral("}");
        }
        readIt(end);
      }
    }
    pragma "no doc"
    proc readThisDefaultImpl(ref x:?t) where !isClassType(t){
      if !binary() {
        var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
        var start:ioLiteral;
        if st == QIO_AGGREGATE_FORMAT_CHPL {
          start = new ioLiteral("new " + t:string + "(");
        } else if st == QIO_AGGREGATE_FORMAT_JSON {
          start = new ioLiteral("{");
        } else {
          start = new ioLiteral("(");
        }
        readIt(start);
      }
  
      var first = true;
  
      readThisFieldsDefaultImpl(t, x, first);
  
      if !binary() {
        var st = styleElement(QIO_STYLE_ELEMENT_AGGREGATE);
        var end:ioLiteral;
        if st == QIO_AGGREGATE_FORMAT_JSON {
          end = new ioLiteral("}");
        } else {
          end = new ioLiteral(")");
        }
        readIt(end);
      }
    }
  }
  
  /* Call w.readwrite(x)

     :returns: w so that ``<~>`` operators can be chained
   */
  inline proc <~>(w: Writer, x):Writer {
    w.readwrite(x);
    return w;
  }
  /* Call r.readwrite(x)

     :returns: r so that ``<~>`` operators can be chained
   */
  inline proc <~>(r: Reader, ref x):Reader {
    r.readwrite(x);
    return r;
  }
  
  use IO;
  
  // these are overridden to not be inout
  // since they don't change when read anyway
  // and it's much more convenient to be able to do e.g.
  //   reader <~> new ioLiteral("=")

  /* Overload to support reading an :type:`IO.ioLiteral` without
     passing ioLiterals by reference, so that

     .. code-block:: chapel

       reader <~> new ioLiteral("=")

     works without requiring an explicit temporary value to store
     the ioLiteral.
   */
  inline proc <~>(r: Reader, lit:ioLiteral):Reader {
    var litCopy = lit;
    r.readwrite(litCopy);
    return r;
  }
  /* Overload to support reading an :type:`IO.ioNewline` without
     passing ioNewline by reference, so that

     .. code-block:: chapel

       reader <~> new ioNewline("=")

     works without requiring an explicit temporary value to store
     the ioNewline.
   */
  inline proc <~>(r: Reader, nl:ioNewline):Reader {
    var nlCopy = nl;
    r.readwrite(nlCopy);
    return r;
  }
  
  /* Explicit call for reading a literal as an
     alternative to using :type:`IO.ioLiteral`.
   */
  inline proc Reader.readWriteLiteral(lit:string, ignoreWhiteSpace=true)
  {
    this.readWriteLiteral(lit.localize().c_str(), ignoreWhiteSpace);
  }
  pragma "no doc"
  inline proc Reader.readWriteLiteral(lit:c_string, ignoreWhiteSpace=true)
  {
    var iolit = new ioLiteral(lit, ignoreWhiteSpace);
    this.readwrite(iolit);
  }
  /* Explicit call for writing a literal as an
     alternative to using :type:`IO.ioLiteral`.
   */
  inline proc Writer.readWriteLiteral(lit:string, ignoreWhiteSpace=true)
  {
    this.readWriteLiteral(lit.localize().c_str(), ignoreWhiteSpace);
  }
  pragma "no doc"
  inline proc Writer.readWriteLiteral(lit:c_string, ignoreWhiteSpace=true)
  {
    var iolit = new ioLiteral(lit, ignoreWhiteSpace);
    this.readwrite(iolit);
  }
  /* Explicit call for reading a newline as an
     alternative to using :type:`IO.ioNewline`.
   */
  inline proc Reader.readWriteNewline()
  {
    var ionl = new ioNewline();
    this.readwrite(ionl);
  }
  /* Explicit call for writing a newline as an
     alternative to using :type:`IO.ioNewline`.
   */
  inline proc Writer.readWriteNewline()
  {
    var ionl = new ioNewline();
    this.readwrite(ionl);
  }
  
  /*
     Prints an error message to stderr giving the location of the call to
     ``halt`` in the Chapel source, followed by the arguments to the call,
     if any, then exits the program.
   */
  proc halt() {
    __primitive("chpl_error", c"halt reached");
  }

  /*
     Prints an error message to stderr giving the location of the call to
     ``halt`` in the Chapel source, followed by the arguments to the call,
     if any, then exits the program.
   */
  proc halt(s:string) {
    halt(s.localize().c_str());
  }

  pragma "no doc"
  proc halt(s:c_string) {
    __primitive("chpl_error", c"halt reached - " + s);
  }
 
  /*
     Prints an error message to stderr giving the location of the call to
     ``halt`` in the Chapel source, followed by the arguments to the call,
     if any, then exits the program.
   */
  proc halt(args ...?numArgs) {
    var tmpstring: string;
    tmpstring.write((...args));
    __primitive("chpl_error", c"halt reached - " + tmpstring.c_str());
  }
  
  /*
    Prints a warning to stderr giving the location of the call to ``warning``
    in the Chapel source, followed by the argument(s) to the call.
  */
  proc warning(s:string) {
    warning(s.localize().c_str());
  }

  pragma "no doc"
  proc warning(s:c_string) {
    __primitive("chpl_warning", s);
  }
 
  /*
    Prints a warning to stderr giving the location of the call to ``warning``
    in the Chapel source, followed by the argument(s) to the call.
  */
  proc warning(args ...?numArgs) {
    var tmpstring: c_string_copy;
    tmpstring.write((...args));
    warning(tmpstring);
    chpl_free_c_string_copy(tmpstring);
  }
  
  pragma "no doc"
  proc _ddata.writeThis(f: Writer) {
    compilerWarning("printing _ddata class");
    f.write("<_ddata class cannot be printed>");
  }

  pragma "no doc"
  proc chpl_taskID_t.writeThis(f: Writer) {
    var tmp : uint(64) = this : uint(64);
    f.write(tmp);
  }

  pragma "no doc"
  proc chpl_taskID_t.readThis(f: Reader) {
    var tmp : uint(64);
    f.read(tmp);
    this = tmp : chpl_taskID_t;
  }
  
  /* Writer that can save output to a string
   */
  class StringWriter: Writer {
    var s: string; // Should be initialized to NULL.
    proc StringWriter(x:string) {
      this.s = x;
    }
    pragma "no doc"
    proc writePrimitive(x) {
      this.s += x:string;
    }
  }
  
  pragma "dont disable remote value forwarding"
  proc ref string.write(args ...?n) {
    var sc = new StringWriter(this);
    sc.write((...args));
    this = sc.s;
    delete sc;
  }

  //
  // When this flag is used during compilation, calls to chpl__testPar
  // will output a message to indicate that a portion of the code has been
  // parallelized.
  //
  pragma "no doc"
  config param chpl__testParFlag = false;
  pragma "no doc"
  var chpl__testParOn = false;
  
  pragma "no doc"
  proc chpl__testParStart() {
    chpl__testParOn = true;
  }
  
  pragma "no doc"
  proc chpl__testParStop() {
    chpl__testParOn = false;
  }
  
  pragma "no doc"
  proc chpl__testPar(args...) {
    if chpl__testParFlag && chpl__testParOn {
      const file : c_string = __primitive("chpl_lookupFilename",
                                          __primitive("_get_user_file"));
      const line = __primitive("_get_user_line");
      writeln("CHPL TEST PAR (", file, ":", line, "): ", (...args));
    }
  }

}
