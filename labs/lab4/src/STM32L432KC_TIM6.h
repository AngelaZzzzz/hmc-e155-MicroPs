// Angela Zheng
// 9/27/2026

// STM32L432KC_TIM6.h
// Header for TIM6 functions

#ifndef STM32L4_TIM6_H
#define STM32L4_TIM6_H

#include <stdint.h>

///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////

#define __IO volatile

// Base addresses
#define TIM6_BASE (0x40001000UL) // base address of TIM6

// Delay prescaler value to set clk to 2kHz
#define TIM6_PSC_VAL 39999

typedef struct
{
  __IO uint32_t CR1;    // Address offset: 0x00
  __IO uint32_t CR2;    // Address offset: 0x04
  uint32_t reserved0;   // Address offset: 0x08
  __IO uint32_t DIER;   // Address offset: 0x0C
  __IO uint32_t SR;     // Address offset: 0x10
  __IO uint32_t EGR;    // Address offset: 0x14
  uint32_t reserved1;   // Address offset: 0x18
  uint32_t reserved2;   // Address offset: 0x1C
  uint32_t reserved3;   // Address offset: 0x20
  __IO uint32_t CNT;    // Address offset: 0x24
  __IO uint32_t PSC;    // Address offset: 0x28
  __IO uint32_t ARR;    // Address offset: 0x2C
} TIM6_TypeDef;

#define TIM6 ((TIM6_TypeDef *) TIM6_BASE)

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void configureTIM6(void);
void duration(int dur);

#endif