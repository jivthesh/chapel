//This tests directly call chpl_comm_get_strd to 
// 1.- get some elements from B on locale 1 to A on locale 0
// 2.- get some elements from B on locale 0 to A on locale 0
// 3.- put some elements from A on locale 0 to B on locale 1
// 4.- put some elements from A on locale 0 to B on locale 0


proc TestGetsPuts(A:[], B:[])
{
  A._value.TestGetsPuts(B);
}


proc BlockArr.TestGetsPuts(B)
{
  param stridelevels=0;
  //  var dststrides:[1..#stridelevels] size_t;
  var dststrides:[1..1] size_t;
  //  var srcstrides: [1..#stridelevels] size_t;
  var srcstrides: [1..1] size_t;
  //  var count: [1..#(stridelevels+1)] size_t;
  var count: [1..2] size_t;
  var rid=1; //remote locale id
  var lid=0; //local locale id

  //  writeln("locArr[0]: ", locArr[0].myElems);
  //  writeln("B._value.locArr[",rid,"].myElems ", B._value.locArr[rid].myElems);

  on Locales[0] {
      dststrides[1]=4;
      srcstrides[1]=2;
      count[1]=2;
      count[2]=4;
      writeln();
      assert(locArr[0].myElems._value.oneDData); // fend off multi-ddata
      var dest = locArr[0].myElems._value.theDataChunk(0); // can this be myLocArr?
      assert(B._value.locArr[lid].myElems._value.oneDData); // fend off multi-ddata
      var srcl = B._value.locArr[lid].myElems._value.theDataChunk(0);
      assert(B._value.locArr[rid].myElems._value.oneDData); // fend off multi-ddata
      var srcr = B._value.locArr[rid].myElems._value.theDataChunk(0);
      assert(dststrides._value.oneDData); // fend off multi-ddata
      var dststr=dststrides._value.theDataChunk(0);
      assert(srcstrides._value.oneDData); // fend off multi-ddata
      var srcstr=srcstrides._value.theDataChunk(0);
      assert(count._value.oneDData); // fend off multi-ddata
      var cnt=count._value.theDataChunk(0);

// 1.- get 2 elements from B (B[58..59]) on locale 1 to A[8..9] on locale 0      
      __primitive("chpl_comm_get_strd",
      		  __primitive("array_get",dest,
      			      locArr[0].myElems._value.getDataIndex(8, getChunked=false)),
      		  __primitive("array_get",dststr,dststrides._value.getDataIndex(1, getChunked=false)),
      		  rid,
      		  __primitive("array_get",srcr,
      			      B._value.locArr[rid].myElems._value.getDataIndex(58, getChunked=false)),
      		  __primitive("array_get",srcstr,srcstrides._value.getDataIndex(1, getChunked=false)),
      		  __primitive("array_get",cnt, count._value.getDataIndex(1, getChunked=false)),
      		  stridelevels);

// 2.- get 2 elements from B (B[8..9]) on locale 0 to A[24..25] on locale 0
      __primitive("chpl_comm_get_strd",
      		  __primitive("array_get",dest,
      			      locArr[0].myElems._value.getDataIndex(24, getChunked=false)),
      		  __primitive("array_get",dststr,dststrides._value.getDataIndex(1, getChunked=false)),
      		  lid,
      		  __primitive("array_get",srcl,
      			      B._value.locArr[lid].myElems._value.getDataIndex(8, getChunked=false)),
      		  __primitive("array_get",srcstr,srcstrides._value.getDataIndex(1, getChunked=false)),
      		  __primitive("array_get",cnt, count._value.getDataIndex(1, getChunked=false)),
      		  stridelevels);

      assert(locArr[0].myElems._value.oneDData); // fend off multi-ddata
      var src = locArr[0].myElems._value.theDataChunk(0); // can this be myLocArr?
      assert(B._value.locArr[lid].myElems._value.oneDData); // fend off multi-ddata
      var destl = B._value.locArr[lid].myElems._value.theDataChunk(0);
      assert(B._value.locArr[rid].myElems._value.oneDData); // fend off multi-ddata
      var destr = B._value.locArr[rid].myElems._value.theDataChunk(0);

// 3.- put 2 elements from A (A[26..27]) on locale 0 to B[76..77] on locale 1
      __primitive("chpl_comm_put_strd",
      		  __primitive("array_get",destr,
			      B._value.locArr[rid].myElems._value.getDataIndex(76, getChunked=false)),
      		  __primitive("array_get",dststr,dststrides._value.getDataIndex(1, getChunked=false)),
      		  rid,
      		  __primitive("array_get",src,
      			      locArr[0].myElems._value.getDataIndex(26, getChunked=false)),
      		  __primitive("array_get",srcstr,srcstrides._value.getDataIndex(1, getChunked=false)),
      		  __primitive("array_get",cnt, count._value.getDataIndex(1, getChunked=false)),
      		  stridelevels);

// 4.- put 2 elements from A (A[2..3]) on locale 0 to B[16..17] on locale 0
      __primitive("chpl_comm_put_strd",
      		  __primitive("array_get",destl,
			      B._value.locArr[lid].myElems._value.getDataIndex(16, getChunked=false)),
      		  __primitive("array_get",dststr,dststrides._value.getDataIndex(1, getChunked=false)),
      		  lid,
      		  __primitive("array_get",src,
      			      locArr[0].myElems._value.getDataIndex(2, getChunked=false)),
      		  __primitive("array_get",srcstr,srcstrides._value.getDataIndex(1, getChunked=false)),
      		  __primitive("array_get",cnt, count._value.getDataIndex(1, getChunked=false)),
      		  stridelevels);

  }
}

use BlockDist;

const n: int=50*numLocales;
var Dist = new dmap(new Block({1..n}));

var Dom: domain(1,int) dmapped Dist = {1..n};

var A:[Dom] int(64); //real
var B:[Dom] int(64); //real

proc main(){

  /* write("A Distribution: "); */

  var a,b:int;
  var i:int;
  for (a,i) in zip(A,{1..n}) do a=i;
  for (b,i) in zip(B,{1..n}) do b=i*100;
  writeln("Original vector:");
  writeln("===================");
  writeln("A= ", A);
  writeln("B= ", B);

  TestGetsPuts(A,B);

  writeln("After gets and puts");

  writeln("A= ", A);
  writeln("B= ", B);

  writeln();

}
