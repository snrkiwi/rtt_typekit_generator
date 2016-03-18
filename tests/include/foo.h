/******************************************************************************
 *  Copyright (c) 2016, Intermodalics BVBA                                    *
 *  All rights reserved.                                                      *
 ******************************************************************************/

#ifndef RTT_TYPEKIT_GENERATOR_TESTS_INCLUDE_FOO_H
#define RTT_TYPEKIT_GENERATOR_TESTS_INCLUDE_FOO_H

#include <iostream>
#include <string>
#include <vector>

#include <Eigen/Core>
#include <kdl_typekit/typekit/Types.hpp>  // for boost::serialization only

namespace foo {

struct Simple {
    std::string member;
};

struct Vector {
    std::vector<std::string> strings;
};

struct Foo {
    double x;
    double y;
    double z;

    struct Bar {
        std::string a;
        std::string b;
        std::string c;
    } bar;
};

typedef Eigen::Vector3d EigenVector;

struct NestedKDL {
    KDL::Vector v;
    std::vector<KDL::Frame> frames;
};

static inline std::ostream &operator<<(std::ostream &os, const Simple &t) {
    return os << "{ \"" << t.member << "\"}";
}

static inline std::istream &operator>>(std::istream &is, Simple &t) {
    return is >> t.member;
}

}  // namespace foo


#include <boost/serialization/nvp.hpp>

namespace boost {
namespace serialization {

template <class Archive>
void serialize(Archive& ar, foo::Simple& v, const unsigned int /* version */) {
    ar & v.member;
}

template <class Archive>
void serialize(Archive& ar, foo::Vector& v, const unsigned int /* version */) {
    ar & boost::serialization::make_nvp("strings", v.strings);
}

template <class Archive>
void serialize(Archive& ar, foo::Foo::Bar& v, const unsigned int /* version */) {
    ar & boost::serialization::make_nvp("a", v.a);
    ar & boost::serialization::make_nvp("b", v.b);
    ar & boost::serialization::make_nvp("c", v.c);
}

template <class Archive>
void serialize(Archive& ar, foo::Foo& v, const unsigned int /* version */) {
    ar & boost::serialization::make_nvp("x", v.x);
    ar & boost::serialization::make_nvp("y", v.y);
    ar & boost::serialization::make_nvp("z", v.z);
    ar & boost::serialization::make_nvp("bar", v.bar);
}

template <class Archive>
void serialize(Archive& ar, foo::EigenVector& v, const unsigned int /* version */) {
    ar & boost::serialization::make_nvp("x", v.x());
    ar & boost::serialization::make_nvp("y", v.y());
    ar & boost::serialization::make_nvp("z", v.z());
}

template <class Archive>
void serialize(Archive& ar, foo::NestedKDL& v, const unsigned int /* version */) {
    ar & boost::serialization::make_nvp("v", v.v);
    ar & boost::serialization::make_nvp("frames", v.frames);
}

}  // namespace serialization
}  // namespace boost

#endif // RTT_TYPEKIT_GENERATOR_TESTS_INCLUDE_FOO_H
