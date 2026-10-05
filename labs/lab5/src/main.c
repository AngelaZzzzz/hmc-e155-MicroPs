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
volatile int direction = 0;

void readPins(void) {
    encoder_A = digitalRead(ENCODER_PIN_9);
    encoder_B = digitalRead(ENCODER_PIN_10);
}

void displayVelocity(void) {
    double angular_velocity = (double) encoder_count / 4 / PPR;
    printf("Angular velocity: %.3f rev/s, Direction: %s.\n", angular_velocity, direction ? "clockwise" : "counter-clockwise");
    encoder_count = 0;      // reset the encoder count
}

// EXTI lines 5-9 share this handler. This is for PA9
void EXTI9_5_IRQHandler(void){
    // Check that ENCODER_PIN_9 was what triggered our interrupt
    if (EXTI->PR1 & (1 << gpioPinOffset(ENCODER_PIN_9))){
        // If so, clear the interrupt (NB: Write 1 to reset.)
        EXTI->PR1 = (1 << gpioPinOffset(ENCODER_PIN_9));
        
        // read PA9 and PA10
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

// EXTI lines 15-10 share this handler. This is for PA10
void EXTI15_10_IRQHandler(void){
    // Check that ENCODER_PIN_10 was what triggered our interrupt
    if (EXTI->PR1 & (1 << gpioPinOffset(ENCODER_PIN_10))){
        // If so, clear the interrupt (NB: Write 1 to reset.)
        EXTI->PR1 = (1 << gpioPinOffset(ENCODER_PIN_10));

        // read PA9 and PA10
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
    pinMode(ENCODER_PIN_9, GPIO_INPUT);
    pinMode(ENCODER_PIN_10, GPIO_INPUT);

    // Pull-ups
    GPIOA->PUPDR |= (0b01 << 2*gpioPinOffset(ENCODER_PIN_9));
    GPIOA->PUPDR |= (0b01 << 2*gpioPinOffset(ENCODER_PIN_10));

    // Initialize timer
    RCC->APB2ENR |= (1 << 17); // TIM16EN
    initTIM(DELAY_TIM);

    // 1. Enable SYSCFG clock domain in RCC
    RCC->APB2ENR |= (1 << 0); // SYSCFGEN

    // 2. Configure EXTICR for the encoder input interrupts
    // EXTI9 and EXTI10 are bits 6:4 and 10:8 of EXTICR3 (EXTICR[2] in C). Port A is 0b000, so clearing the fields selects PA9 and PA10.
    SYSCFG->EXTICR[2] &= ~(0b111 << 4);
    SYSCFG->EXTICR[2] &= ~(0b111 << 8);

    // Enable interrupts globally
    __enable_irq();
    
    // 3. Unmask line 9 and 10
    EXTI->IMR1 |= (1 << gpioPinOffset(ENCODER_PIN_9));
    EXTI->IMR1 |= (1 << gpioPinOffset(ENCODER_PIN_10));

    // 4. Trigger on rising edges
    EXTI->RTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_9));
    EXTI->RTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_10));

    // 5. Trigger on falling edges
    EXTI->FTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_9));
    EXTI->FTSR1 |= (1 << gpioPinOffset(ENCODER_PIN_10));

    // 6. Turn on EXTI interrupt in NVIC_ISER (EXTI9_5 is IRQ 23 and EXTI15_10 is IRQ 40)
    NVIC->ISER[0] |= (1 << 23);
    NVIC->ISER[1] |= (1 << 8);

    while(1){
        delay_millis(DELAY_TIM, 1000);  // count for 1 s
        displayVelocity();
    }
}
