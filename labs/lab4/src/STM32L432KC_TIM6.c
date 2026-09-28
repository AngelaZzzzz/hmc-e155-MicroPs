// Angela Zheng
// 9/27/2026

// STM32L432KC_TIM6.c
// Source code for TIM6 functions

#include "STM32L432KC_RCC.h"
#include "STM32L432KC_TIM6.h"

void configureTIM6() {
    // enable TIM6 in APB1
    RCC->APB1ENR1 |= (1 << 4);

    // set ARR to NOT buffered
    TIM6->CR1 &= ~(1 << 7);

    // enable counter in CR1
    TIM6->CR1 |= (1 << 0);

    // set the prescaler in PSC
    TIM6->PSC = TIM6_PSC_VAL;
}

void duration(int dur) {
    // reset clock to avoid new arr being lower than previous
    TIM6->CNT = 0;

    // change the ARR based on duration of the note
    TIM6->ARR = 2 * dur - 1;

    // generate an event to update the counter in EGR
    TIM6->EGR |= (1 << 0);

    // wait until arr (max count) is reached, while SR == 0
    while((TIM6->SR & 1) == 0);
}
