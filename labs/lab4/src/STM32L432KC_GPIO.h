// Angela Zheng
// 9/26/2026
//
// STM32L432KC_GPIO.h

#ifndef GPIO_H
#define GPIO_H

#include <stdint.h>

// Base address
#define GPIOA_BASE = (0x48000000UL);


// GPIO register struct
typedef struct {
    volatile uint32_t MODER;        // offset 0x00
    volatile uint32_t OTYPER;       // offset 0x04
    volatile uint32_t OSPEEDR;      // offset 0x08
    volatile uint32_t PUPDR;        // offset 0x0C
    volatile uint32_t IDR;          // offset ox10
    volatile uint32_t ODR;          // offset 0x14
    volatile uint32_t BSRR;         // offset 0x18
    volatile uint32_t LCKR;         // offset 0x1C
    volatile uint32_t AFRL;         // offset 0x20
    volatile uint32_t AFRH;         // offset 0x24
    volatile uint32_t BRR;          // offset 0x28
} GPIO;

#endif