/******************************************************************************
 *  Copyright (c) 2016, Intermodalics BVBA                                    *
 *  All rights reserved.                                                      *
 ******************************************************************************/

#ifndef RTT_TYPEKIT_GENERATOR_ARCHIVE_H
#define RTT_TYPEKIT_GENERATOR_ARCHIVE_H

#include <boost/serialization/nvp.hpp>
#include <boost/serialization/serialization.hpp>

namespace boost {
namespace serialization {

// default implementation - do nothing
template<class Archive, class T>
inline bool introspect(Archive& ar, const T&, const BOOST_PFTO unsigned int file_version) {
    return false;
}

template <class Archive, class T>
bool introspect_adl(Archive& ar, const T& t, const BOOST_PFTO unsigned int file_version) {
    // note usage of function overloading to delay final resolution
    // until the point of instantiation.  This works around the two-phase
    // lookup "feature" which inhibits redefintion of a default function
    // template implementation. Due to Robert Ramey
    //
    // Note that this trick generates problems for compiles which don't support
    // PFTO, suppress it here.  As far as we know, there are no compilers
    // which fail to support PFTO while supporting two-phase lookup.
    #if ! defined(BOOST_NO_FUNCTION_TEMPLATE_ORDERING)
        const version_type v(file_version);
        return introspect(ar, t, v);
    #else
        return introspect(ar, t, file_version);
    #endif
}

}  // namespace serialization
}  // namespace boost


namespace rtt_typekit_generator {

/**
 * Implements the Boost serialization Loading Archive Concept
 */
template <class IntrospectorT>
class Archive {
public:
    typedef typename IntrospectorT::type type;

    Archive(IntrospectorT *introspector, const type &prototype)
        : introspector_(introspector)
        , prototype_(const_cast<type &>(prototype))
    {}

    typedef boost::mpl::bool_<true> is_loading;
    typedef boost::mpl::bool_<false> is_saving;
    unsigned int get_library_version() { return 0; }
    void reset_object_address(const void *new_address, const void *old_address) {}
    void delete_created_pointers() {}
    template <class T> void register_type(T* = 0) { return 0; }

    void operator()() {
        boost::serialization::serialize_adl(*this, prototype_, get_library_version());
    }

    template <class T>
    Archive &operator>>(T &t) {
        introspect(t);
        return *this;
    }

    template <class T>
    Archive &operator&(T &t) {
        introspect(t);
        return *this;
    }

    template <class T>
    void introspect(T &t) {
        introspector_->introspect<T>(0, t, prototype_);
    }

    template <class T>
    void introspect(T (type::*t)) {
        introspector_->introspect<T>(0, t, prototype_);
    }

    template <class T>
    void introspect(const char *name, T &t) {
        introspector_->introspect<T>(name, t, prototype_);
    }

    template <class T>
    void introspect(const char *name, T (type::*t)) {
        introspector_->introspect<T>(name, t, prototype_);
    }

    template <typename T>
    void introspect(const boost::serialization::nvp<T> &t) {
        introspector_->introspect<T>(t.name(), t.value(), prototype_);
    }

private:
    IntrospectorT *introspector_;
    type &prototype_;
};

} // namespace rtt_typekit_generator

#endif // RTT_TYPEKIT_GENERATOR_ARCHIVE_H
