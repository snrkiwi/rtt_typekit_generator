#ifndef RTT_TYPEKIT_GENERATOR_RTT_TYPEINFO_HPP
#define RTT_TYPEKIT_GENERATOR_RTT_TYPEINFO_HPP

#include <rtt_typekit_generator/introspection.h>
#include <rtt/types/TemplateTypeInfo.hpp>
#include <boost/type_traits/has_left_shift.hpp>

namespace rtt_typekit_generator {

template <typename T>
class TypeInfo : public RTT::types::TemplateTypeInfo<
    T,
    boost::has_left_shift<std::ostream, T>::value
> {
public:
    static const bool has_ostream = boost::has_left_shift<std::ostream, T>::value;
    typedef RTT::types::TemplateTypeInfo<T, has_ostream> base_type;

    TypeInfo(TypeIntrospection<T> *introspector)
        : base_type(introspector->getName())
    {
    }

    virtual ~TypeInfo() {}

    bool installTypeInfoObject(TypeInfo* ti) {
        // aquire a shared reference to the this object
        boost::shared_ptr< StructTypeInfo<T,has_ostream> > mthis = boost::dynamic_pointer_cast<StructTypeInfo<T,has_ostream> >( this->getSharedPtr() );
        assert(mthis);

        // Allow base to install first
        base_type::installTypeInfoObject(ti);

        // Install the factories for primitive types
        ti->setMemberFactory( mthis );

        // Don't delete us, we're memory-managed.
        return false;
    }

private:
    boost::shared_ptr< TypeIntrospection<T> > introspector_;
};

}  // namespace rtt_typekit_generator

#endif // RTT_TYPEKIT_GENERATOR_RTT_TYPEINFO_HPP
