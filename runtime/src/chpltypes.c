#include <math.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <chplfp.h>
#include "chplmem.h"
#include "chplrt.h"
#include "chpltypes.h"
#include "error.h"

#define NANSTRING "nan"
#define NEGINFSTRING "-inf"
#define POSINFSTRING "inf"

const char* _default_format_write_complex64 = "%g + %gi";
const char* _default_format_write_complex128 = "%g + %gi";

char* _glom_strings(int numstrings, ...) {
  va_list ap;
  int i, len;
  char* str;

  va_start(ap, numstrings);
  len = 0;
  for (i=0; i<numstrings; i++)
    len += strlen(va_arg(ap, char*));
  va_end(ap);

  str = (char*)chpl_malloc(len+1, sizeof(char), "_glom_strings result", 0, 0);

  va_start(ap, numstrings);
  str[0] = '\0';
  for (i=0; i<numstrings; i++)
    strcat(str, va_arg(ap, char*));
  va_end(ap);

  return str;
}


_string _format(_string format, ...) {
  va_list ap;
  char z[128];

  va_start(ap, format);
  if (!vsnprintf(z, 127, format, ap))
    chpl_error("overflow encountered in format", 0, 0);
  return string_copy(z, 0, 0);
}


_string
string_concat(_string x, _string y, int32_t lineno, _string filename) {
  char *z = (char*)chpl_malloc(strlen(x)+strlen(y)+1, sizeof(char),
                                "string_concat", lineno, filename);
  z[0] = '\0';
  strcat(z, x);
  strcat(z, y);
  return z;
}


_string
string_strided_select(_string x, int low, int high, int stride, int32_t lineno, _string filename) {
  int64_t length = string_length(x);
  char* result = NULL;
  char* dst = NULL;
  _string src = stride > 0 ? x + low - 1 : x + high - 1;
  int size = high - low >= 0 ? high - low : 0;
  if (low < 1 || low > length || high > length) {
    chpl_error("string index out of bounds", lineno, filename);
  }
  result = chpl_malloc(size + 2, sizeof(char), "_chpl_string_strided_select temp", lineno, filename);
  dst = result;
  if (stride > 0) {
    while (src - x <= high - 1) {
      *dst++ = *src;
      src += stride;
    }
  } else {
    while (src - x >= low - 1) {
      *dst++ = *src;
      src += stride;
    }
  }
  *dst = '\0';
  return _glom_strings(1, result);
}

_string
string_select(_string x, int low, int high, int32_t lineno, _string filename) {
  return string_strided_select(x, low, high, 1, lineno, filename);
}

_string
string_index(_string x, int i, int32_t lineno, _string filename) {
  char buffer[2];
  if (i-1 < 0 || i-1 >= string_length(x))
    chpl_error("string index out of bounds", lineno, filename);
  sprintf(buffer, "%c", x[i-1]);
  return _glom_strings(1, buffer);
}


chpl_bool
string_contains(_string x, _string y) {
  if (strstr(x, y))
    return true;
  else
    return false;
}


int32_t _string_compare(_string x, _string y) {
  return (int32_t)strcmp(x, y);
}


int64_t
string_length(_string x) {
  return strlen(x);
}


int64_t real2int( _real64 f) {
  // need to use a union here rather than a pointer cast to avoid gcc
  // warnings when compiling -O3
  union {     
    _real64 r;
    uint64_t u;
  } converter;

  converter.r = f;
  return converter.u;
}


int64_t 
object2int( _chpl_object o) {
  return (intptr_t) o;
}


_timervalue* _now_timer_help(_timervalue* time) {
  gettimeofday(time, NULL);
  return time;
}
_timervalue _default_timer;

int32_t _now_year(void) {
  struct tm * now;
  _timervalue t;
  gettimeofday(&t, NULL);
  now = localtime(&t.tv_sec);
  return now->tm_year;
}

int32_t _now_month(void) {
  struct tm * now;
  _timervalue t;
  gettimeofday(&t, NULL);
  now = localtime(&t.tv_sec);
  return now->tm_mon;
}

int32_t _now_day(void) {
  struct tm * now;
  _timervalue t;
  gettimeofday(&t, NULL);
  now = localtime(&t.tv_sec);
  return now->tm_mday;
}

int32_t _now_dow(void) {
  struct tm * now;
  _timervalue t;
  gettimeofday(&t, NULL);
  now = localtime(&t.tv_sec);
  return now->tm_wday;
}


_real64 _now_time(void) {
  struct tm * now;
  _timervalue t;
  gettimeofday(&t, NULL);
  now = localtime(&t.tv_sec);
  return (_real64)(now->tm_hour)*3600.0e+6 +
    (_real64)(now->tm_min)*60.0e+6 +
    (_real64)(now->tm_sec)*1.0e+6 +
    (_real64)(t.tv_usec);
}
