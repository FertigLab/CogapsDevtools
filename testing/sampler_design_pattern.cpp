#include <iostream>

class DenseStorage
{
public:
    DenseStorage() { std::cout << "Dense ctor" << std::endl; }
    void pingBase() { std::cout << "pinging dense" << std::endl; }
};

class SparseStorage
{
public:
    SparseStorage() { std::cout << "Sparse ctor" << std::endl; }
    void pingBase() { std::cout << "pinging sparse" << std::endl; }
};

template <class StoragePolicy>
class SingleThreadedGibbsSampler : public StoragePolicy
{
public:
    SingleThreadedGibbsSampler() { std::cout << "single-threaded ctor" << std::endl; }    
    void pingDerived() { std::cout << "pinging single-threaded" << std::endl; }
    void ping() { pingDerived(); base().pingBase(); }
    StoragePolicy& base() { return static_cast<StoragePolicy&>(*this); }
};

template <class StoragePolicy>
class AsynchronousGibbsSampler : public StoragePolicy
{
public:
    AsynchronousGibbsSampler() { std::cout << "async ctor" << std::endl; }
    void pingDerived() { std::cout << "pinging async" << std::endl; }
    void ping() { pingDerived(); base().pingBase(); }
    StoragePolicy& base() { return static_cast<StoragePolicy&>(*this); }
};

int main()
{
    SingleThreadedGibbsSampler<SparseStorage> s1;
    s1.pingBase();
    s1.ping();
    std::cout << std::endl;
    
    SingleThreadedGibbsSampler<DenseStorage> s2;
    s2.pingBase();
    s2.ping();
    std::cout << std::endl;

    AsynchronousGibbsSampler<SparseStorage> s3;
    s3.pingBase();
    s3.ping();
    std::cout << std::endl;

    AsynchronousGibbsSampler<DenseStorage> s4;
    s4.pingBase();
    s4.ping();
    std::cout << std::endl;
}
