#include <ddnet_base/base/system.h>

using namespace ddnet_base;

int main()
{
	dbg_assert(false, "this fails because %d is not 10", 2);
}
