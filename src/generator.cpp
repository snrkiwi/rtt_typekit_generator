/******************************************************************************
 *  Copyright (c) 2016, Intermodalics BVBA                                    *
 *  All rights reserved.                                                      *
 ******************************************************************************/

#include <rtt_typekit_generator/generator.h>

#include <boost/filesystem.hpp>

namespace rtt_typekit_generator {

PartGeneratorBase::PartGeneratorBase(const std::string &type_name,
                                     const std::string &c_type_name)
    : context_stack_(new ContextStack)
    , type_name_(type_name)
    , c_type_name_(c_type_name)
    , parent_(0)
{
    parseNamespaces();
}

PartGeneratorBase::PartGeneratorBase(PartGeneratorBase *parent,
                                     const std::string &type_name,
                                     const std::string &c_type_name)
    : context_stack_(parent->context_stack_)
    , type_name_(parent->getTypeName() + "/" + type_name)
    , c_type_name_(c_type_name)
    , namespaces_(parent->namespaces_)
    , parent_(parent)
{
    parseNamespaces();
}

void PartGeneratorBase::parseNamespaces()
{
    size_t namespace_separator_pos = 0;
    while((namespace_separator_pos = c_type_name_.find("::", namespace_separator_pos)) != std::string::npos) {
        if (namespace_separator_pos == 0) {
            namespaces_.clear();
            continue;
        }
        namespaces_.push_back(c_type_name_.substr(0, namespace_separator_pos));
        try {
            c_type_name_ = c_type_name_.substr(namespace_separator_pos + 2);
        } catch(std::out_of_range&) {
            break;
        }
        namespace_separator_pos = 0;
    }
}

PartGeneratorBase::~PartGeneratorBase()
{
    if (!parent_) {
        delete context_stack_;
    }
}

PartGeneratorBase::StaticInitializer::StaticInitializer(
        const char *transport,
        const PartGeneratorBase::shared_ptr &generator) {
    if (!generator) return;
    TransportGeneratorRepository::Instance()
            ->at(transport)
            ->part_generators_[generator->getTypeName()][generator->getPartName()] = generator;
}

PartGeneratorBase::ContextData &PartGeneratorBase::context() const
{
    assert(!context_stack_->empty());
    return dynamic_cast<ContextData &>(*context_stack_->top());
}

std::ostream &PartGeneratorBase::stream() const
{
    return *(context().stream);
}

std::string PartGeneratorBase::indent() const
{
    return std::string(context().indent, ' ');
}

std::string PartGeneratorBase::indent(int diff)
{
    if (diff > 0) {
        std::string s = std::string(context().indent, ' ');
        context().indent += diff;
        return s;
    } else {
        context().indent -= -diff;
        return std::string(context().indent, ' ');
    }
}

PartGeneratorBase *PartGeneratorBase::parent() const
{
    return parent_;
}

TransportGeneratorBase::~TransportGeneratorBase()
{}

TransportGeneratorBase::StaticInitializer::StaticInitializer(
        const char *transport,
        const TransportGeneratorBase::shared_ptr &generator) {
    if (!generator) return;
    (*TransportGeneratorRepository::Instance())[transport] = generator;
}

TransportGeneratorRepository::shared_ptr TransportGeneratorRepository::Instance()
{
    static shared_ptr the_instance;
    if (!the_instance) {
        the_instance.reset(new TransportGeneratorRepository);
    }
    return the_instance;
}

TransportGeneratorRepository::TransportGeneratorRepository()
{}

std::ostream &operator<<(std::ostream &os, PartGeneratorBase::ContextData &context)
{
    return context >> os;
}

} // namespace rtt_typekit_generator


using namespace rtt_typekit_generator;

int main(int argc, char **argv) {
    TransportGeneratorRepository::shared_ptr transports
            = TransportGeneratorRepository::Instance();
    for(TransportGeneratorRepository::const_iterator it = transports->begin();
        it != transports->end(); ++it)
    {
        std::string output_directory = it->first + "/";
        TransportGeneratorBase::shared_ptr generator = it->second;

        if (!boost::filesystem::exists(output_directory)) {
            boost::filesystem::create_directory(output_directory);
        }

        std::clog << "Generating " << generator->getDescription() << "..."
                  << std::endl;
        generator->generate(output_directory);
    }

    return 0;
}
