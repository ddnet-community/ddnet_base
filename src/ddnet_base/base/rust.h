#ifndef BASE_RUST_H
#define BASE_RUST_H
namespace ddnet_base
{
	typedef const char *StrRef;
	typedef void *UserPtr;

	extern "C" void rust_panic_use_dbg_assert();
} // end namespace
#endif // BASE_RUST_H
