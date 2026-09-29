// Angela Zheng
// 9/27/2026

// STM32L432KC_TIM16.c
// Source code for TIM16 functions

#include "STM32L432KC_RCC.h"
#include "STM32L432KC_TIM16.h"

void configureTIM16(void) {
    // enable TIM16 in APB2
    RCC->APB2ENR = (1 << 17);

    // set prescaler
    TIM16->PSC = TIM16_PSC_VAL;

    // select PWM mode 1 in CCMR
    // by writting 110 in the OCxM bits in the CCMR register
    TIM16->CCMR1_out |= (1 << 6);
    TIM16->CCMR1_out |= (1 << 5);
    TIM16->CCMR1_out &= ~(1 << 4);

    // enable the preload register
    TIM16->CCMR1_out |= (1 << 3);

    // sets to output
    TIM16->CCMR1_out &= ~(0b11 << 0);

    // enable the auto-reload preload register
    TIM16->CR1 |= (1 << 7);

    // set PWM capture/compare 1 output polarity to active high, and enable output
    TIM16->CCER &= ~(1 << 1);
    TIM16->CCER |= (1 << 0);

    // enable outputs
    TIM16->BDTR |= (1 << 15);

    // initialize all registers by setting UG in EGR
    TIM16->EGR |= (1 << 0);

    // enable counter
    TIM16->CR1 |= (1 << 0);
}

void frequency(int hz) {
    uint32_t arr = 0;

    // compute arr
    if (hz == 0) {
        arr = 0;
    } else {
        arr = (80000000 / (TIM16_PSC_VAL + 1)) / hz - 1;
    }

    // set ARR
    TIM16->ARR = arr;

    // set duty cycle to 50%
    TIM16->CCR1 = arr / 2;

    // reset all registers
    TIM16->EGR |= (1 << 0);

    // reset clock to avoid new arr being lower than previous
    TIM16->CNT = 0;
}
