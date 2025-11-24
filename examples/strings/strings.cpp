#include <ddnet_base/base/str.h>

#include <cstdio>

using namespace ddnet_base;

int main()
{
	char aBuf[512] = "";
	str_append(aBuf, "hello");
	str_append(aBuf, " ");
	str_append(aBuf, "world");
	puts(aBuf);
}
