// Angela Zheng
// 9/27/2026

// STM32L432KC_TIM16.h
// Header for TIM16 functions

#ifndef STM32L4_TIM16_H
#define STM32L4_TIM16_H

#include <stdint.h>

///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////

#define __IO volatile

// Base addresses
#define TIM16_BASE (0x40014400UL) // base address of TIM16

// Prescaler for TIM16 to set clk to 5MHz
#define TIM16_PSC_VAL 15

typedef struct
{
  __IO uint32_t CR1;        // Address offset: 0x00
  __IO uint32_t CR2;        // Address offset: 0x04
  uint32_t reserved0;       // Address offset: 0x08
  __IO uint32_t DIER;       // Address offset: 0x0C
  __IO uint32_t SR;         // Address offset: 0x10
  __IO uint32_t EGR;        // Address offset: 0x14
  __IO uint32_t CCMR1_out;  // Address offset: 0x18
  __IO uint32_t CCMR1_in;   // Address offset: 0x1C
  __IO uint32_t CCER;       // Address offset: 0x20
  __IO uint32_t CNT;        // Address offset: 0x24
  __IO uint32_t PSC;        // Address offset: 0x28
  __IO uint32_t ARR;        // Address offset: 0x2C
  __IO uint32_t RCR;        // Address offset: 0x30
  __IO uint32_t CCR1;       // Address offset: 0x34
  uint32_t reserved1;       // Address offset: 0x38
  uint32_t reserved2;       // Address offset: 0x3C
  uint32_t reserved3;       // Address offset: 0x40
  __IO uint32_t BDTR;       // Address offset: 0x44
  __IO uint32_t DCR;        // Address offset: 0x48
  __IO uint32_t DMAR;       // Address offset: 0x4C
  __IO uint32_t OR1;        // Address offset: 0x50
  uint32_t reserved4;       // Address offset: 0x54
  uint32_t reserved5;       // Address offset: 0x58
  uint32_t reserved6;       // Address offset: 0x5C
  __IO uint32_t OR2;        // Address offset: 0x60
} TIM16_TypeDef;

#define TIM16 ((TIM16_TypeDef *) TIM16_BASE)

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

void configureTIM16(void);
void frequency(int hz);

#endif