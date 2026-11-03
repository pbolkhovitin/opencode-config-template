# C/C++ Instructions

## Toolchain
- C: gcc/clang
- C++: g++/clang++
- Build: CMake + Make / Ninja
- Lint: clang-tidy / cppcheck
- Sanitizers: AddressSanitizer, UndefinedBehaviorSanitizer

## Commands (CMake)
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
ctest --test-dir build -V
```

## Commands (direct)
```bash
gcc -Wall -Wextra -O2 -o output source.c
g++ -std=c++20 -Wall -Wextra -O2 -o output source.cpp
```

## Sanitizers
```bash
cmake -B build -DCMAKE_BUILD_TYPE=Debug \
  -DCMAKE_C_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer" \
  -DCMAKE_CXX_FLAGS="-fsanitize=address,undefined -fno-omit-frame-pointer"
```

## Conventions
- C: snake_case for functions/variables
- C++: PascalCase for classes, camelCase for methods
- RAII — no raw new/delete
- Prefer `std::vector`, `std::string` over C arrays/char*
- Use `constexpr` where possible
- Include guards: `#pragma once` (preferred) or `#ifndef`

## Verify
```bash
gcc --version && g++ --version && cmake --version && clang-tidy --version
```
