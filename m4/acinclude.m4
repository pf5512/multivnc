dnl Available from the GNU Autoconf Macro Archive at:
dnl http://www.gnu.org/software/ac-archive/htmldoc/ax_prefix_config_h.html
dnl
AC_DEFUN([AX_PREFIX_CONFIG_H],[AC_REQUIRE([AC_CONFIG_HEADER])
AC_CONFIG_COMMANDS([ifelse($1,,$PACKAGE-config.h,$1)],[dnl
AS_VAR_PUSHDEF([_OUT],[ac_prefix_conf_OUT])dnl
AS_VAR_PUSHDEF([_DEF],[ac_prefix_conf_DEF])dnl
AS_VAR_PUSHDEF([_PKG],[ac_prefix_conf_PKG])dnl
AS_VAR_PUSHDEF([_LOW],[ac_prefix_conf_LOW])dnl
AS_VAR_PUSHDEF([_UPP],[ac_prefix_conf_UPP])dnl
AS_VAR_PUSHDEF([_INP],[ac_prefix_conf_INP])dnl
m4_pushdef([_script],[conftest.prefix])dnl
m4_pushdef([_symbol],[m4_cr_Letters[]m4_cr_digits[]_])dnl
_OUT=`echo ifelse($1, , $PACKAGE-config.h, $1)`
_DEF=`echo _$_OUT | sed -e "y:m4_cr_letters:m4_cr_LETTERS[]:" -e "s/@<:@^m4_cr_Letters@:>@/_/g"`
_PKG=`echo ifelse($2, , $PACKAGE, $2)`
_LOW=`echo _$_PKG | sed -e "y:m4_cr_LETTERS-:m4_cr_letters[]_:"`
_UPP=`echo $_PKG | sed -e "y:m4_cr_letters-:m4_cr_LETTERS[]_:"  -e "/^@<:@m4_cr_digits@:>@/s/^/_/"`
_INP=`echo ifelse($3, , _, $3)`
if test "$ac_prefix_conf_INP" = "_"; then
   for ac_file in : $CONFIG_HEADERS; do test "_$ac_file" = _: && continue
     test -f "$ac_prefix_conf_INP" && continue
     case $ac_file in
        *.h) test -f $ac_file && _INP=$ac_file ;;
        *)
     esac
   done
fi
if test "$_INP" = "_"; then
   case "$_OUT" in
      */*) _INP=`basename "$_OUT"`
      ;;
      *-*) _INP=`echo "$_OUT" | sed -e "s/@<:@_symbol@:>@*-//"`
      ;;
      *) _INP=config.h
      ;;
   esac
fi
if test -z "$_PKG" ; then
   AC_MSG_ERROR([no prefix for _PREFIX_PKG_CONFIG_H])
else
  if test ! -f "$_INP" ; then if test -f "$srcdir/$_INP" ; then
     _INP="$srcdir/$_INP"
  fi fi
  AC_MSG_NOTICE(creating $_OUT - prefix $_UPP for $_INP defines)
  if test -f $_INP ; then
    echo "s/@%:@undef  *\\(@<:@m4_cr_LETTERS[]_@:>@\\)/@%:@undef $_UPP""_\\1/" > _script
    # no! these are things like socklen_t, const, vfork
    # echo "s/@%:@undef  *\\(@<:@m4_cr_letters@:>@\\)/@%:@undef $_LOW""_\\1/" >> _script
    echo "s/@%:@def[]ine  *\\(@<:@m4_cr_LETTERS[]_@:>@@<:@_symbol@:>@*\\)\\(.*\\)/@%:@ifndef $_UPP""_\\1 \\" >> _script
    echo "@%:@def[]ine $_UPP""_\\1 \\2 \\" >> _script
    echo "@%:@endif/" >>_script
    # no! these are things like socklen_t, const, vfork
    # echo "s/@%:@def[]ine  *\\(@<:@m4_cr_letters@:>@@<:@_symbol@:>@*\\)\\(.*\\)/@%:@ifndef $_LOW""_\\1 \\" >> _script
    # echo "@%:@define $_LOW""_\\1 \\2 \\" >> _script
    # echo "@%:@endif/" >> _script
    # now executing _script on _DEF input to create _OUT output file
    echo "@%:@ifndef $_DEF"      >$tmp/pconfig.h
    echo "@%:@def[]ine $_DEF 1" >>$tmp/pconfig.h
    echo ' ' >>$tmp/pconfig.h
    echo /'*' $_OUT. Generated automatically at end of configure. '*'/ >>$tmp/pconfig.h

    sed -f _script $_INP >>$tmp/pconfig.h
    echo ' ' >>$tmp/pconfig.h
    echo '/* once:' $_DEF '*/' >>$tmp/pconfig.h
    echo "@%:@endif" >>$tmp/pconfig.h
    if cmp -s $_OUT $tmp/pconfig.h 2>/dev/null; then
      AC_MSG_NOTICE([$_OUT is unchanged])
    else
      ac_dir=`AS_DIRNAME(["$_OUT"])`
      AS_MKDIR_P(["$ac_dir"])
      rm -f "$_OUT"
      mv $tmp/pconfig.h "$_OUT"
    fi
    cp _script _configs.sed
  else
    AC_MSG_ERROR([input file $_INP does not exist - skip generating $_OUT])
  fi
  rm -f conftest.*
fi
m4_popdef([_symbol])dnl
m4_popdef([_script])dnl
AS_VAR_POPDEF([_INP])dnl
AS_VAR_POPDEF([_UPP])dnl
AS_VAR_POPDEF([_LOW])dnl
AS_VAR_POPDEF([_PKG])dnl
AS_VAR_POPDEF([_DEF])dnl
AS_VAR_POPDEF([_OUT])dnl
],[PACKAGE="$PACKAGE"])])





AH_TEMPLATE(socklen_t, [The type for socklen])
AC_DEFUN([AC_TYPE_SOCKLEN_T],
[AC_CACHE_CHECK([for socklen_t], ac_cv_type_socklen_t,
[
  AC_TRY_COMPILE(
  [#include <sys/types.h>
   #include <sys/socket.h>],
  [socklen_t len = 42; return 0;],
  ac_cv_type_socklen_t=yes,
  ac_cv_type_socklen_t=no)
])
  if test $ac_cv_type_socklen_t != yes; then
    AC_DEFINE(socklen_t, int)
  fi
])



dnl Available from the GNU Autoconf Macro Archive at:
dnl http://www.gnu.org/software/ac-archive/htmldoc/ac_compile_check_sizeof.html
dnl
AC_DEFUN([AC_COMPILE_CHECK_SIZEOF],
[changequote(<<, >>)dnl
dnl The name to #define.
define(<<AC_TYPE_NAME>>, translit(sizeof_$1, [a-z *], [A-Z_P]))dnl
dnl The cache variable name.
define(<<AC_CV_NAME>>, translit(ac_cv_sizeof_$1, [ *], [_p]))dnl
changequote([, ])dnl
AC_MSG_CHECKING(size of $1)
AC_CACHE_VAL(AC_CV_NAME,
[for ac_size in 4 8 1 2 16 $2 ; do # List sizes in rough order of prevalence.
  AC_TRY_COMPILE([#include "confdefs.h"
#include <sys/types.h>
$2
], [switch (0) case 0: case (sizeof ($1) == $ac_size):;], AC_CV_NAME=$ac_size)
  if test x$AC_CV_NAME != x ; then break; fi
done
])
if test x$AC_CV_NAME = x ; then
  AC_MSG_ERROR([cannot determine a size for $1])
fi
AC_MSG_RESULT($AC_CV_NAME)
AC_DEFINE_UNQUOTED(AC_TYPE_NAME, $AC_CV_NAME, [The number of bytes in type $1])
undefine([AC_TYPE_NAME])dnl
undefine([AC_CV_NAME])dnl
])




dnl Available from the GNU Autoconf Macro Archive at:
dnl http://www.gnu.org/software/ac-archive/htmldoc/ac_create_stdint_h.html
dnl
AC_DEFUN([AC_CREATE_STDINT_H],
[# ------ AC CREATE STDINT H -------------------------------------
AC_MSG_CHECKING([for stdint-types....])
ac_stdint_h=`echo ifelse($1, , _stdint.h, $1)`
if test "$ac_stdint_h" = "stdint.h" ; then
 AC_MSG_RESULT("(are you sure you want them in ./stdint.h?)")
elif test "$ac_stdint_h" = "inttypes.h" ; then
 AC_MSG_RESULT("(are you sure you want them in ./inttypes.h?)")
else
 AC_MSG_RESULT("(putting them into $ac_stdint_h)")
fi

inttype_headers=`echo inttypes.h sys/inttypes.h sys/inttypes.h $2 \
| sed -e 's/,/ /g'`

 ac_cv_header_stdint_x="no-file"
 ac_cv_header_stdint_o="no-file"
 ac_cv_header_stdint_u="no-file"
 for i in stdint.h $inttype_headers ; do
   unset ac_cv_type_uintptr_t
   unset ac_cv_type_uint64_t
   _AC_CHECK_TYPE_NEW(uintptr_t,[ac_cv_header_stdint_x=$i],dnl
     continue,[#include <$i>])
   AC_CHECK_TYPE(uint64_t,[and64="(uint64_t too)"],[and64=""],[#include<$i>])
   AC_MSG_RESULT(... seen our uintptr_t in $i $and64)
   break;
 done
 if test "$ac_cv_header_stdint_x" = "no-file" ; then
 for i in stdint.h $inttype_headers ; do
   unset ac_cv_type_uint32_t
   unset ac_cv_type_uint64_t
   AC_CHECK_TYPE(uint32_t,[ac_cv_header_stdint_o=$i],dnl
     continue,[#include <$i>])
   AC_CHECK_TYPE(uint64_t,[and64="(uint64_t too)"],[and64=""],[#include<$i>])
   AC_MSG_RESULT(... seen our uint32_t in $i $and64)
   break;
 done
 if test "$ac_cv_header_stdint_o" = "no-file" ; then
 for i in sys/types.h $inttype_headers ; do
   unset ac_cv_type_u_int32_t
   unset ac_cv_type_u_int64_t
   AC_CHECK_TYPE(u_int32_t,[ac_cv_header_stdint_u=$i],dnl
     continue,[#include <$i>])
   AC_CHECK_TYPE(uint64_t,[and64="(u_int64_t too)"],[and64=""],[#include<$i>])
   AC_MSG_RESULT(... seen our u_int32_t in $i $and64)
   break;
 done
 fi
 fi

# ----------------- DONE inttypes.h checks MAYBE C basic types --------

if test "$ac_cv_header_stdint_x" = "no-file" ; then
   AC_COMPILE_CHECK_SIZEOF(char)
   AC_COMPILE_CHECK_SIZEOF(short)
   AC_COMPILE_CHECK_SIZEOF(int)
   AC_COMPILE_CHECK_SIZEOF(long)
   AC_COMPILE_CHECK_SIZEOF(void*)
   ac_cv_header_stdint_test="yes"
else
   ac_cv_header_stdint_test="no"
fi

# ----------------- DONE inttypes.h checks START header -------------
_ac_stdint_h=AS_TR_CPP(_$ac_stdint_h)
AC_MSG_RESULT(creating $ac_stdint_h : $_ac_stdint_h)
echo "#ifndef" $_ac_stdint_h >$ac_stdint_h
echo "#define" $_ac_stdint_h "1" >>$ac_stdint_h
echo "#ifndef" _GENERATED_STDINT_H >>$ac_stdint_h
echo "#define" _GENERATED_STDINT_H '"'$PACKAGE $VERSION'"' >>$ac_stdint_h
if test "$GCC" = "yes" ; then
  echo "/* generated using a gnu compiler version" `$CC --version` "*/" \
  >>$ac_stdint_h
else
  echo "/* generated using $CC */" >>$ac_stdint_h
fi
echo "" >>$ac_stdint_h

if test "$ac_cv_header_stdint_x" != "no-file" ; then
   ac_cv_header_stdint="$ac_cv_header_stdint_x"
elif  test "$ac_cv_header_stdint_o" != "no-file" ; then
   ac_cv_header_stdint="$ac_cv_header_stdint_o"
elif  test "$ac_cv_header_stdint_u" != "no-file" ; then
   ac_cv_header_stdint="$ac_cv_header_stdint_u"
else
   ac_cv_header_stdint="stddef.h"
fi

# ----------------- See if int_least and int_fast types are present
unset ac_cv_type_int_least32_t
unset ac_cv_type_int_fast32_t
AC_CHECK_TYPE(int_least32_t,,,[#include <$ac_cv_header_stdint>])
AC_CHECK_TYPE(int_fast32_t,,,[#include<$ac_cv_header_stdint>])

if test "$ac_cv_header_stdint" != "stddef.h" ; then
if test "$ac_cv_header_stdint" != "stdint.h" ; then
AC_MSG_RESULT(..adding include stddef.h)
   echo "#include <stddef.h>" >>$ac_stdint_h
fi ; fi
AC_MSG_RESULT(..adding include $ac_cv_header_stdint)
   echo "#include <$ac_cv_header_stdint>" >>$ac_stdint_h
echo "" >>$ac_stdint_h

# ----------------- DONE header START basic int types -------------
if test "$ac_cv_header_stdint_x" = "no-file" ; then
   AC_MSG_RESULT(... need to look at C basic types)
dnl ac_cv_header_stdint_test="yes" # moved up before creating the file
else
   AC_MSG_RESULT(... seen good stdint.h inttypes)
dnl ac_cv_header_stdint_test="no"  # moved up before creating the file
fi

if test "$ac_cv_header_stdint_u" != "no-file" ; then
   AC_MSG_RESULT(... seen bsd/sysv typedefs)
   cat >>$ac_stdint_h <<EOF

/* int8_t int16_t int32_t defined by inet code, redeclare the u_intXX types */
typedef u_int8_t uint8_t;
typedef u_int16_t uint16_t;
typedef u_int32_t uint32_t;
EOF
    cat >>$ac_stdint_h <<EOF

/* glibc compatibility */
#ifndef __int8_t_defined
#define __int8_t_defined
#endif
EOF
fi

ac_cv_sizeof_x="$ac_cv_sizeof_char:$ac_cv_sizeof_short"
ac_cv_sizeof_X="$ac_cv_sizeof_x:$ac_cv_sizeof_int"
ac_cv_sizeof_X="$ac_cv_sizeof_X:$ac_cv_sizeof_voidp:$ac_cv_sizeof_long"
if test "$ac_cv_header_stdint" = "stddef.h" ; then
#   we must guess all the basic types. Apart from byte-adressable system,
# there a few 32-bit-only dsp-systems. nibble-addressable systems are way off.
    cat >>$ac_stdint_h <<EOF
/* ------------ BITSPECIFIC INTTYPES SECTION --------------- */
EOF
    t="typedefs for a"
    case "$ac_cv_sizeof_X" in
     1:2:2:2:4) AC_MSG_RESULT(..adding $t normal 16-bit system)
                cat >>$ac_stdint_h <<EOF
/*              a normal 16-bit system                       */
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned long   uint32_t;
#ifndef __int8_t_defined
#define __int8_t_defined
typedef          char    int8_t;
typedef          short   int16_t;
typedef          long    int32_t;
#endif
EOF
;;
     1:2:2:4:4) AC_MSG_RESULT(..adding $t 32-bit system derived from a 16-bit)
                cat >>$ac_stdint_h <<EOF
/*              a 32-bit system derived from a 16-bit        */
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;
#ifndef __int8_t_defined
#define __int8_t_defined
typedef          char    int8_t;
typedef          short   int16_t;
typedef          int     int32_t;
#endif
EOF
;;
     1:2:4:4:4) AC_MSG_RESULT(..adding $t normal 32-bit system)
                cat >>$ac_stdint_h <<EOF
/*              a normal 32-bit system                       */
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;
#ifndef __int8_t_defined
#define __int8_t_defined
typedef          char    int8_t;
typedef          short   int16_t;
typedef          int     int32_t;
#endif
EOF
;;
     1:2:4:4:8) AC_MSG_RESULT(..adding $t 32-bit system prepared for 64-bit)
                cat >>$ac_stdint_h <<EOF

/*              a 32-bit system prepared for 64-bit          */
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;
#ifndef __int8_t_defined
#define __int8_t_defined
typedef          char    int8_t;
typedef          short   int16_t;
typedef          int     int32_t;
#endif
EOF
;;
     1:2:4:8:8) AC_MSG_RESULT(..adding $t normal 64-bit system)
                cat >>$ac_stdint_h <<EOF

/*              a normal 64-bit system                       */
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;
#ifndef __int8_t_defined
#define __int8_t_defined
typedef          char    int8_t;
typedef          short   int16_t;
typedef          int     int32_t;
#endif
EOF
;;
     1:2:4:8:4) AC_MSG_RESULT(..adding $t 64-bit system derived from a 32-bit)
                cat >>$ac_stdint_h <<EOF

/*              a 64-bit system derived from a 32-bit system */
typedef unsigned char   uint8_t;
typedef unsigned short  uint16_t;
typedef unsigned int    uint32_t;
#ifndef __int8_t_defined
#define __int8_t_defined
typedef          char    int8_t;
typedef          short   int16_t;
typedef          int     int32_t;
#endif
EOF
;;
  *)
    AC_MSG_ERROR([ $ac_cv_sizeof_X dnl
 what is that a system? contact the author, quick! http://ac-archive.sf.net])
    exit 1
;;
   esac
fi

# ------------- DONE basic int types START int64_t types ------------
if test "$ac_cv_type_uint64_t" = "yes"
then AC_MSG_RESULT(... seen good uint64_t)
     cat >>$ac_stdint_h <<EOF

/* system headers have good uint64_t */
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
#endif
EOF

elif test "$ac_cv_type_u_int64_t" = "yes"
then AC_MSG_RESULT(..adding typedef u_int64_t uint64_t)
     cat >>$ac_stdint_h <<EOF

/* system headers have an u_int64_t */
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef u_int64_t uint64_t;
#endif
EOF
else AC_MSG_RESULT(..adding generic uint64_t runtime checks)
     cat >>$ac_stdint_h <<EOF

/* -------------------- 64 BIT GENERIC SECTION -------------------- */
/* here are some common heuristics using compiler runtime specifics */
#if defined __STDC_VERSION__ && defined __STDC_VERSION__ > 199901L

#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef long long int64_t;
typedef unsigned long long uint64_t;
#endif

#elif !defined __STRICT_ANSI__
#if defined _MSC_VER || defined __WATCOMC__ || defined __BORLANDC__

#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;
#endif

#elif defined __GNUC__ || defined __MWERKS__ || defined __ELF__
dnl /* note: all ELF-systems seem to have loff-support which needs 64-bit */

#if !defined _NO_LONGLONG
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef long long int64_t;
typedef unsigned long long uint64_t;
#endif
#endif

#elif defined __alpha || (defined __mips && defined _ABIN32)

#if !defined _NO_LONGLONG
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef long int64_t;
typedef unsigned long uint64_t;
#endif
#endif
  /* compiler/cpu type ... or just ISO C99 */
#endif
#endif
EOF

# plus a default 64-bit for systems that are likely to be 64-bit ready
  case "$ac_cv_sizeof_x:$ac_cv_sizeof_voidp:$ac_cv_sizeof_long" in
    1:2:8:8) AC_MSG_RESULT(..adding uint64_t default, normal 64-bit system)
cat >>$ac_stdint_h <<EOF
/* DEFAULT: */
/* seen normal 64-bit system, CC has sizeof(long and void*) == 8 bytes */
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef long int64_t;
typedef unsigned long uint64_t;
#endif
EOF
;;
    1:2:4:8) AC_MSG_RESULT(..adding uint64_t default, typedef to long)
cat >>$ac_stdint_h <<EOF
/* DEFAULT: */
/* seen 32-bit system prepared for 64-bit, CC has sizeof(long) == 8 bytes */
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef long int64_t;
typedef unsigned long uint64_t;
#endif
EOF
;;
    1:2:8:4) AC_MSG_RESULT(..adding uint64_t default, typedef long long)
cat >>$ac_stdint_h <<EOF
/* DEFAULT: */
/* seen 64-bit derived from a 32-bit, CC has sizeof(long) == 4 bytes */
#ifndef _HAVE_UINT64_T
#define _HAVE_UINT64_T
typedef long long int64_t;
typedef unsigned long long uint64_t;
#endif
EOF
;;
   *)
cat >>$ac_stdint_h <<EOF
/* NOTE: */
/* the configure-checks for the basic types did not make us believe */
/* that we could add a fallback to a 'long long' typedef to int64_t */
EOF
  esac
fi

# ------------- DONE int64_t types START intptr types ------------
if test "$ac_cv_header_stdint_x" = "no-file" ; then
  cat >>$ac_stdint_h <<EOF

/* -------------------------- INPTR SECTION --------------------------- */
EOF
  case "$ac_cv_sizeof_x:$ac_cv_sizeof_voidp" in
  1:2:2)
    a="int16_t" ; cat >>$ac_stdint_h <<EOF
/* we tested sizeof(void*) to be of 2 chars, hence we declare it 16-bit */

typedef uint16_t uintptr_t;
typedef  int16_t  intptr_t;
EOF
;;
  1:2:4)
    a="int32_t" ; cat >>$ac_stdint_h <<EOF
/* we tested sizeof(void*) to be of 4 chars, hence we declare it 32-bit */

typedef uint32_t uintptr_t;
typedef  int32_t  intptr_t;
EOF
;;
  1:2:8)
    a="int64_t" ; cat >>$ac_stdint_h <<EOF
/* we tested sizeof(void*) to be of 8 chars, hence we declare it 64-bit */

typedef uint64_t uintptr_t;
typedef  int64_t  intptr_t;
EOF
;;
  *)
    a="long" ; cat >>$ac_stdint_h <<EOF
/* we tested sizeof(void*) but got no guess, hence we declare it as if long */

typedef unsigned long uintptr_t;
typedef          long  intptr_t;
EOF
;;
  esac
AC_MSG_RESULT(..adding typedef $a intptr_t)
fi

# ------------- DONE intptr types START int_least types ------------
if test "$ac_cv_type_int_least32_t" = "no"; then
AC_MSG_RESULT(..adding generic int_least-types)
     cat >>$ac_stdint_h <<EOF

/* --------------GENERIC INT_LEAST ------------------ */

typedef  int8_t    int_least8_t;
typedef  int16_t   int_least16_t;
typedef  int32_t   int_least32_t;
#ifdef _HAVE_INT64_T
typedef  int64_t   int_least64_t;
#endif

typedef uint8_t   uint_least8_t;
typedef uint16_t  uint_least16_t;
typedef uint32_t  uint_least32_t;
#ifdef _HAVE_INT64_T
typedef uint64_t  uint_least64_t;
#endif
EOF
fi

# ------------- DONE intptr types START int_least types ------------
if test "$ac_cv_type_int_fast32_t" = "no"; then
AC_MSG_RESULT(..adding generic int_fast-types)
     cat >>$ac_stdint_h <<EOF

/* --------------GENERIC INT_FAST ------------------ */

typedef  int8_t    int_fast8_t;
typedef  int32_t   int_fast16_t;
typedef  int32_t   int_fast32_t;
#ifdef _HAVE_INT64_T
typedef  int64_t   int_fast64_t;
#endif

typedef uint8_t   uint_fast8_t;
typedef uint32_t  uint_fast16_t;
typedef uint32_t  uint_fast32_t;
#ifdef _HAVE_INT64_T
typedef uint64_t  uint_fast64_t;
#endif
EOF
fi

if test "$ac_cv_header_stdint_x" = "no-file" ; then
     cat >>$ac_stdint_h <<EOF

#ifdef _HAVE_INT64_T
typedef int64_t        intmax_t;
typedef uint64_t      uintmax_t;
#else
typedef long int       intmax_t;
typedef unsigned long uintmax_t;
#endif
EOF
fi

AC_MSG_RESULT(... DONE $ac_stdint_h)
   cat >>$ac_stdint_h <<EOF

  /* once */
#endif
#endif
EOF
])

dnl quote from SunOS-5.8 sys/inttypes.h:
dnl Use at your own risk.  As of February 1996, the committee is squarely
dnl behind the fixed sized types; the "least" and "fast" types are still being
dnl discussed.  The probability that the "fast" types may be removed before
dnl the standard is finalized is high enough that they are not currently
dnl implemented.



dnl Autoconf macros for libgcrypt
dnl       Copyright (C) 2002, 2004 Free Software Foundation, Inc.
dnl
dnl This file is free software; as a special exception the author gives
dnl unlimited permission to copy and/or distribute it, with or without
dnl modifications, as long as this notice is preserved.
dnl
dnl This file is distributed in the hope that it will be useful, but
dnl WITHOUT ANY WARRANTY, to the extent permitted by law; without even the
dnl implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.


dnl AM_PATH_LIBGCRYPT([MINIMUM-VERSION,
dnl                   [ACTION-IF-FOUND [, ACTION-IF-NOT-FOUND ]]])
dnl Test for libgcrypt and define LIBGCRYPT_CFLAGS and LIBGCRYPT_LIBS.
dnl MINIMUN-VERSION is a string with the version number optionalliy prefixed
dnl with the API version to also check the API compatibility. Example:
dnl a MINIMUN-VERSION of 1:1.2.5 won't pass the test unless the installed 
dnl version of libgcrypt is at least 1.2.5 *and* the API number is 1.  Using
dnl this features allows to prevent build against newer versions of libgcrypt
dnl with a changed API.
dnl
AC_DEFUN([AM_PATH_LIBGCRYPT],
[ AC_ARG_WITH(libgcrypt-prefix,
            AC_HELP_STRING([--with-libgcrypt-prefix=PFX],
                           [prefix where LIBGCRYPT is installed (optional)]),
     libgcrypt_config_prefix="$withval", libgcrypt_config_prefix="")
  if test x$libgcrypt_config_prefix != x ; then
     if test x${LIBGCRYPT_CONFIG+set} != xset ; then
        LIBGCRYPT_CONFIG=$libgcrypt_config_prefix/bin/libgcrypt-config
     fi
  fi

  AC_PATH_PROG(LIBGCRYPT_CONFIG, libgcrypt-config, no)
  tmp=ifelse([$1], ,1:1.2.0,$1)
  if echo "$tmp" | grep ':' >/dev/null 2>/dev/null ; then
     req_libgcrypt_api=`echo "$tmp"     | sed 's/\(.*\):\(.*\)/\1/'`
     min_libgcrypt_version=`echo "$tmp" | sed 's/\(.*\):\(.*\)/\2/'`
  else
     req_libgcrypt_api=0
     min_libgcrypt_version="$tmp"
  fi

  AC_MSG_CHECKING(for LIBGCRYPT - version >= $min_libgcrypt_version)
  ok=no
  if test "$LIBGCRYPT_CONFIG" != "no" ; then
    req_major=`echo $min_libgcrypt_version | \
               sed 's/\([[0-9]]*\)\.\([[0-9]]*\)\.\([[0-9]]*\)/\1/'`
    req_minor=`echo $min_libgcrypt_version | \
               sed 's/\([[0-9]]*\)\.\([[0-9]]*\)\.\([[0-9]]*\)/\2/'`
    req_micro=`echo $min_libgcrypt_version | \
               sed 's/\([[0-9]]*\)\.\([[0-9]]*\)\.\([[0-9]]*\)/\3/'`
    libgcrypt_config_version=`$LIBGCRYPT_CONFIG --version`
    major=`echo $libgcrypt_config_version | \
               sed 's/\([[0-9]]*\)\.\([[0-9]]*\)\.\([[0-9]]*\).*/\1/'`
    minor=`echo $libgcrypt_config_version | \
               sed 's/\([[0-9]]*\)\.\([[0-9]]*\)\.\([[0-9]]*\).*/\2/'`
    micro=`echo $libgcrypt_config_version | \
               sed 's/\([[0-9]]*\)\.\([[0-9]]*\)\.\([[0-9]]*\).*/\3/'`
    if test "$major" -gt "$req_major"; then
        ok=yes
    else 
        if test "$major" -eq "$req_major"; then
            if test "$minor" -gt "$req_minor"; then
               ok=yes
            else
               if test "$minor" -eq "$req_minor"; then
                   if test "$micro" -ge "$req_micro"; then
                     ok=yes
                   fi
               fi
            fi
        fi
    fi
  fi
  if test $ok = yes; then
    AC_MSG_RESULT([yes ($libgcrypt_config_version)])
  else
    AC_MSG_RESULT(no)
  fi
  if test $ok = yes; then
     # If we have a recent libgcrypt, we should also check that the
     # API is compatible
     if test "$req_libgcrypt_api" -gt 0 ; then
        tmp=`$LIBGCRYPT_CONFIG --api-version 2>/dev/null || echo 0`
        if test "$tmp" -gt 0 ; then
           AC_MSG_CHECKING([LIBGCRYPT API version])
           if test "$req_libgcrypt_api" -eq "$tmp" ; then
             AC_MSG_RESULT([okay])
           else
             ok=no
             AC_MSG_RESULT([does not match. want=$req_libgcrypt_api got=$tmp])
           fi
        fi
     fi
  fi
  if test $ok = yes; then
    LIBGCRYPT_CFLAGS=`$LIBGCRYPT_CONFIG --cflags`
    LIBGCRYPT_LIBS=`$LIBGCRYPT_CONFIG --libs`
    ifelse([$2], , :, [$2])
  else
    LIBGCRYPT_CFLAGS=""
    LIBGCRYPT_LIBS=""
    ifelse([$3], , :, [$3])
  fi
  AC_SUBST(LIBGCRYPT_CFLAGS)
  AC_SUBST(LIBGCRYPT_LIBS)
])












# pkg.m4 - Macros to locate and utilise pkg-config.            -*- Autoconf -*-
# serial 1 (pkg-config-0.24)
# 
# Copyright © 2004 Scott James Remnant <scott@netsplit.com>.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
# As a special exception to the GNU General Public License, if you
# distribute this file as part of a program that contains a
# configuration script generated by Autoconf, you may include it under
# the same distribution terms that you use for the rest of that program.

# PKG_PROG_PKG_CONFIG([MIN-VERSION])
# ----------------------------------
AC_DEFUN([PKG_PROG_PKG_CONFIG],
[m4_pattern_forbid([^_?PKG_[A-Z_]+$])
m4_pattern_allow([^PKG_CONFIG(_PATH)?$])
AC_ARG_VAR([PKG_CONFIG], [path to pkg-config utility])
AC_ARG_VAR([PKG_CONFIG_PATH], [directories to add to pkg-config's search path])
AC_ARG_VAR([PKG_CONFIG_LIBDIR], [path overriding pkg-config's built-in search path])

if test "x$ac_cv_env_PKG_CONFIG_set" != "xset"; then
	AC_PATH_TOOL([PKG_CONFIG], [pkg-config])
fi
if test -n "$PKG_CONFIG"; then
	_pkg_min_version=m4_default([$1], [0.9.0])
	AC_MSG_CHECKING([pkg-config is at least version $_pkg_min_version])
	if $PKG_CONFIG --atleast-pkgconfig-version $_pkg_min_version; then
		AC_MSG_RESULT([yes])
	else
		AC_MSG_RESULT([no])
		PKG_CONFIG=""
	fi
fi[]dnl
])# PKG_PROG_PKG_CONFIG

# PKG_CHECK_EXISTS(MODULES, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
#
# Check to see whether a particular set of modules exists.  Similar
# to PKG_CHECK_MODULES(), but does not set variables or print errors.
#
# Please remember that m4 expands AC_REQUIRE([PKG_PROG_PKG_CONFIG])
# only at the first occurence in configure.ac, so if the first place
# it's called might be skipped (such as if it is within an "if", you
# have to call PKG_CHECK_EXISTS manually
# --------------------------------------------------------------
AC_DEFUN([PKG_CHECK_EXISTS],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])dnl
if test -n "$PKG_CONFIG" && \
    AC_RUN_LOG([$PKG_CONFIG --exists --print-errors "$1"]); then
  m4_default([$2], [:])
m4_ifvaln([$3], [else
  $3])dnl
fi])

# _PKG_CONFIG([VARIABLE], [COMMAND], [MODULES])
# ---------------------------------------------
m4_define([_PKG_CONFIG],
[if test -n "$$1"; then
    pkg_cv_[]$1="$$1"
 elif test -n "$PKG_CONFIG"; then
    PKG_CHECK_EXISTS([$3],
                     [pkg_cv_[]$1=`$PKG_CONFIG --[]$2 "$3" 2>/dev/null`],
		     [pkg_failed=yes])
 else
    pkg_failed=untried
fi[]dnl
])# _PKG_CONFIG

# _PKG_SHORT_ERRORS_SUPPORTED
# -----------------------------
AC_DEFUN([_PKG_SHORT_ERRORS_SUPPORTED],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])
if $PKG_CONFIG --atleast-pkgconfig-version 0.20; then
        _pkg_short_errors_supported=yes
else
        _pkg_short_errors_supported=no
fi[]dnl
])# _PKG_SHORT_ERRORS_SUPPORTED


# PKG_CHECK_MODULES(VARIABLE-PREFIX, MODULES, [ACTION-IF-FOUND],
# [ACTION-IF-NOT-FOUND])
#
#
# Note that if there is a possibility the first call to
# PKG_CHECK_MODULES might not happen, you should be sure to include an
# explicit call to PKG_PROG_PKG_CONFIG in your configure.ac
#
#
# --------------------------------------------------------------
AC_DEFUN([PKG_CHECK_MODULES],
[AC_REQUIRE([PKG_PROG_PKG_CONFIG])dnl
AC_ARG_VAR([$1][_CFLAGS], [C compiler flags for $1, overriding pkg-config])dnl
AC_ARG_VAR([$1][_LIBS], [linker flags for $1, overriding pkg-config])dnl

pkg_failed=no
AC_MSG_CHECKING([for $1])

_PKG_CONFIG([$1][_CFLAGS], [cflags], [$2])
_PKG_CONFIG([$1][_LIBS], [libs], [$2])

m4_define([_PKG_TEXT], [Alternatively, you may set the environment variables $1[]_CFLAGS
and $1[]_LIBS to avoid the need to call pkg-config.
See the pkg-config man page for more details.])

if test $pkg_failed = yes; then
   	AC_MSG_RESULT([no])
        _PKG_SHORT_ERRORS_SUPPORTED
        if test $_pkg_short_errors_supported = yes; then
	        $1[]_PKG_ERRORS=`$PKG_CONFIG --short-errors --print-errors "$2" 2>&1`
        else 
	        $1[]_PKG_ERRORS=`$PKG_CONFIG --print-errors "$2" 2>&1`
        fi
	# Put the nasty error message in config.log where it belongs
	echo "$$1[]_PKG_ERRORS" >&AS_MESSAGE_LOG_FD

	m4_default([$4], [AC_MSG_ERROR(
[Package requirements ($2) were not met:

$$1_PKG_ERRORS

Consider adjusting the PKG_CONFIG_PATH environment variable if you
installed software in a non-standard prefix.

_PKG_TEXT])dnl
        ])
elif test $pkg_failed = untried; then
     	AC_MSG_RESULT([no])
	m4_default([$4], [AC_MSG_FAILURE(
[The pkg-config script could not be found or is too old.  Make sure it
is in your PATH or set the PKG_CONFIG environment variable to the full
path to pkg-config.

_PKG_TEXT

To get pkg-config, see <http://pkg-config.freedesktop.org/>.])dnl
        ])
else
	$1[]_CFLAGS=$pkg_cv_[]$1[]_CFLAGS
	$1[]_LIBS=$pkg_cv_[]$1[]_LIBS
        AC_MSG_RESULT([yes])
	$3
fi[]dnl
])# PKG_CHECK_MODULES



