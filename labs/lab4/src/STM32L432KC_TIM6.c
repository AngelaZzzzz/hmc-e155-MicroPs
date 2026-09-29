// Angela Zheng
// 9/27/2026

// STM32L432KC_TIM6.c
// Source code for TIM6 functions

#include "STM32L432KC_RCC.h"
#include "STM32L432KC_TIM6.h"

void configureTIM6(void) {
    // enable TIM6 in APB1
    RCC->APB1ENR1 |= (1 << 4);

    // set the prescaler in PSC
    TIM6->PSC = TIM6_PSC_VAL;

    // generate an event to update the counter in EGR
    TIM6->EGR |= (1 << 0);

    // set ARR to buffered
    TIM6->CR1 |= (1 << 7);

    // enable counter in CR1
    TIM6->CR1 |= (1 << 0);
}

void duration(int dur) {
    // change the ARR based on duration of the note
    TIM6->ARR = 2 * dur - 1;

    // generate an event to update the counter in EGR
    TIM6->EGR |= (1 << 0);

    // reset SR
    TIM6->SR &= ~(1 << 0);

    // enable counter in CR1 just in case
    TIM6->CR1 |= (1 << 0);

    // reset clock to avoid new arr being lower than previous
    TIM6->CNT = 0;

    // wait until arr (max count) is reached, aka while SR == 0
    while((TIM6->SR & 1) == 0);

    // disable counter in CR1 just in case
    TIM6->CR1 &= ~(1 << 0);
}
