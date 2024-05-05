#pragma once

#include <stdint.h>
#include <stdbool.h>

#ifndef NULL
#define NULL    0
#endif

typedef uint8_t u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uint64_t u64;

typedef volatile u32 reg32;

typedef unsigned long long int process;

// typedef  void(*process_code_adr)(void*, void*);

typedef  void* process_code_adr;

