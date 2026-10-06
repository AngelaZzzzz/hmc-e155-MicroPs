// main.c
// Angela Zheng
// angzheng@hmc.edu
// 10/4/2026

#include <stdio.h>
#include "stm32l432xx.h"
#include "main.h"

volatile int encoder_A = 0;
volatile int encoder_B = 0;
volatile int encoder_count = 0;

void readPins(void) {
    encoder_A = digitalRead(ENCODER_PIN_A);
    encoder_B = digitalRead(ENCODER_PIN_B);
}

void displayVelocity(void) {
    double angular_velocity = (double) encoder_count / 4 / PPR;
    printf("Angular velocity: %.3f rev/s, Direction: %s.\n", angular_velocity, (angular_velocity > 0) ? "clockwise" : "counter-clockwise");
    encoder_count = 0;      // reset the encoder count
}

// EXTI lines 5-9 share this handler. This is for PA8
void EXTI9_5_IRQHandler(void){
    // Check that ENCODER_PIN_9 was what triggered our interrupt
    if (EXTI->PR1 & (1 << gpioPinOffset(ENCODER_PIN_A))){
        // If so, clear the interrupt (NB: Write 1 to reset.)
        EXTI->PR1 = (1 << gpioPinOffset(ENCODER_PIN_A));
        
        // read PA8 and PA12
        readPins();

        // If encoder A leads, then the motor is spinning clockwise
        // otherwise, the motor is spinning counterclockwise
        if (encoder_A != encoder_B) {
            encoder_count++;
        } else {
            encoder_count--;
        }

    }
}

// EXTI lines 15-10 share this handler. This is for PA12
void EXTI15_10_IRQHandler(void){
    // Check that ENCODER_PIN_10 was what triggered our interrupt
    if (EXTI->PR1 & (1 << gpioPinOffset(ENCODER_PIN_B))){
        // If so, clear the interrupt (NB: Write 1 to reset.)
        EXTI->PR1 = (1 << gpioPinOffset(ENCODER_PIN_B));

        // read PA8 and PA12
        readPins();

        // If encoder B leads, then the motor is spinning counterclockwise
        // otherwise, the motor is spinning clockwise
        if (encoder_A != encoder_B) {
            encoder_count--;
        } else {
            encoder_count++;
        }

    }
}

int main(void) {
    // Enable port A clock and set encoder pins as inputs
    gpioEnable(GPIO_PORT_A);
    pinMode(ENCODER_PIN_A, GPIO_INPUT);
    pinMode(ENCODER_PIN_B, GPIO_INPUT);
    // pinMode(POLLING_PIN, GPIO_OUTPUT);

    // Pull-ups
    GPIOA->PUPDR &= ~(0b11 << 2*gpioPinOffset(ENCODER_PIN_A));
    GPIOA->PUPDR &= ~(0b11 << 2*gpioPinOffset(ENCODER_PIN_B));
    GPIOA->PUPDR |= (0b01 << 2*gpioPinOffset(ENCODER_PIN_A));
    GPIOA->PUPDR |= (0b01 << 2*gpioPinOffset(ENCODER_PIN_B));

    // Initialize timer
    RCC->APB2ENR |= (1 << 17); // TIM16EN
    initTIM(DELAY_TIM);

    // 1. Enable SYSCFG clock domain in RCC
    RCC->APB2ENR |= (1 << 0); // SYSCFGEN

    // 2. Configure EXTICR for the encoder input interrupts
    // EXTI8 and EXTI12 are bits 2:0 of EXTICR3 and EXTICR4 (EXTICR[2] and EXTICR[3] in C). Port A is 0b000, so clearing the fields selects PA8 and PA12.
    SYSCFG->EXTICR[2] &= ~(0b111 << 0);
    SYSCFG->EXTICR[3] &= ~(0b111 << 0);

    // Enable interrupts globally
    __enable_irq();
    
    // 3. Unmask line 8 and 12
    EXTI->IMR1 |= (1 << gpioPinOffset(ENCODER_PIN_A));
    EXTI->IMR1 |= (1 << gpioPinOffset(ENCODER_PIN_B));

    // 4. Trigger on rising edges
    EXTI->RTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_A));
    EXTI->RTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_B));

    // 5. Trigger on falling edges
    EXTI->FTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_A));
    EXTI->FTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_B));

    // 6. Turn on EXTI interrupt in NVIC_ISER (EXTI9_5 is IRQ 23 and EXTI15_10 is IRQ 40)
    NVIC->ISER[0] |= (1 << 23);
    NVIC->ISER[1] |= (1 << 8);

    // while(1){
    //     GPIOA->ODR ^= (1 << gpioPinOffset(POLLING_PIN));
    //     printf("A: %d, B: %d\n", digitalRead(ENCODER_PIN_A), digitalRead(ENCODER_PIN_B));
    //     printf("A: %d, B: %d\n", digitalRead(ENCODER_PIN_A), digitalRead(ENCODER_PIN_B));
    // }
    while(1){
        delay_millis(DELAY_TIM, 1000);  // 1s delay
        displayVelocity();
    }
}
