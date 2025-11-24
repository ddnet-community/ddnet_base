# ddnet_base

The core helpers from the ddnet project as standalone library.
The code in src/ is mostly a direct copy from https://github.com/ddnet/ddnet/.
Full credits go to the ddnet contributors.

```cpp
// sample.cpp

#include <cstdio>
#include <ddnet_base/base/str.h>

using namespace ddnet_base;

int main() {
        char aBuf[512];
        str_copy(aBuf, "foo");
        printf("%s\n", aBuf);
}
```

```
mkdir build
cd build
cmake ..
make install
g++ sample.cpp -lddnet_base
./a.out # => foo
```

## macOS dependency

On macOS there is an external dependency that you need to link to make it work.


If you use cmake you can just add this section to your CMakeLists.txt

```cmake
if(APPLE)
	find_library(CORE_FOUNDATION_LIBRARY CoreFoundation REQUIRED)
	target_link_libraries(your_target PRIVATE ${CORE_FOUNDATION_LIBRARY})
endif()
```

And if you use make or a manual compile command just compile it like this:

```bash
g++ your_code.cpp -lddnet_base -framework CoreFoundation
```
