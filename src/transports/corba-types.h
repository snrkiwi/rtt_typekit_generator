/******************************************************************************
 *  Copyright (c) 2016, Intermodalics BVBA                                    *
 *  All rights reserved.                                                      *
 ******************************************************************************/

#ifndef RTT_TYPEKIT_GENERATOR_CORBA_TYPES_H
#define RTT_TYPEKIT_GENERATOR_CORBA_TYPES_H

#include <boost/type_traits/integral_constant.hpp>
#include <boost/preprocessor/seq/enum.hpp>

#include <string>

namespace rtt_typekit_generator {
namespace corba {

template <typename T>
struct CorbaType {
    typedef T type;
    typedef type value_type;
    typedef boost::false_type is_native;
    typedef boost::true_type is_struct;
    typedef boost::false_type is_sequence;

    static const char *getTypeName() { return "(unknown)"; }
    static const char *getCTypeName() { return ""; }
    static const char *getIDLTypeName() { return "any"; }
};

#define DEFINE_NATIVE_CORBA_TYPE(_type, _name, _idl_name) \
    template <> \
    struct CorbaType< _type > { \
        typedef _type type; \
        typedef type value_type; \
        typedef boost::true_type is_native; \
        typedef boost::false_type is_struct; \
        typedef boost::false_type is_sequence; \
        static const char *getTypeName() { return _name; } \
        static const char *getCTypeName() { return #_type; } \
        static const char *getIDLTypeName() { return _idl_name; } \
    }

#define DEFINE_NATIVE_CORBA_TYPE_TEMPLATE(_type, _name, _idl_name, \
                                          _template_parameter_list, \
                                          _template_parameter_arguments) \
    template <BOOST_PP_SEQ_ENUM(_template_parameter_list)> \
    struct CorbaType< _type<BOOST_PP_SEQ_ENUM(_template_parameter_arguments)> > { \
        typedef _type<BOOST_PP_SEQ_ENUM(_template_parameter_arguments)> type; \
        typedef type value_type; \
        typedef boost::true_type is_native; \
        typedef boost::false_type is_struct; \
        typedef boost::false_type is_sequence; \
        static const char *getTypeName() { return _name; } \
        static const char *getCTypeName() { return #_type; } \
        static const char *getIDLTypeName() { return _idl_name; } \
    }

DEFINE_NATIVE_CORBA_TYPE(float, "float", "float");
DEFINE_NATIVE_CORBA_TYPE(double, "double", "double");
DEFINE_NATIVE_CORBA_TYPE(long double, "long double", "long double");
DEFINE_NATIVE_CORBA_TYPE(signed short int, "short", "short");
DEFINE_NATIVE_CORBA_TYPE(signed long int, "long", "long");
DEFINE_NATIVE_CORBA_TYPE(signed long long int, "long long", "long long");
DEFINE_NATIVE_CORBA_TYPE(unsigned short int, "unsigned short", "unsigned short");
DEFINE_NATIVE_CORBA_TYPE(unsigned long int, "unsigned long", "unsigned long");
DEFINE_NATIVE_CORBA_TYPE(unsigned long long int, "unsigned long long", "unsigned long long");
DEFINE_NATIVE_CORBA_TYPE(char, "char", "char");
DEFINE_NATIVE_CORBA_TYPE(wchar_t, "wchar", "wchar");
DEFINE_NATIVE_CORBA_TYPE(bool, "bool", "boolean");
DEFINE_NATIVE_CORBA_TYPE(unsigned char, "unsigned char", "octet");
DEFINE_NATIVE_CORBA_TYPE_TEMPLATE(std::basic_string, "string", "string", (class traits)(class Alloc), (char)(traits)(Alloc));
DEFINE_NATIVE_CORBA_TYPE_TEMPLATE(std::basic_string, "wstring", "wstring", (class traits)(class Alloc), (wchar_t)(traits)(Alloc));

// Sequence types
template <typename T>
struct CorbaType< std::vector<T> > {
    typedef std::vector<T> type;
    typedef T value_type;
    typedef boost::false_type is_native;
    typedef boost::false_type is_struct;
    typedef boost::true_type is_sequence;

    static const char *getTypeName() { CorbaType<T>::getTypeName(); }
    static const char *getCTypeName() { CorbaType<T>::getCTypeName(); }
    static const char *getIDLTypeName() { CorbaType<T>::getIDLTypeName(); }
};

}  // namespace corba
}  // namespace rtt_typekit_generator

#endif // RTT_TYPEKIT_GENERATOR_CORBA_TYPES_H
