// main.h
// Josh Brake
// jbrake@hmc.edu
// 10/31/22

#ifndef MAIN_H
#define MAIN_H

#include "STM32L432KC.h"
#include <stm32l432xx.h>

///////////////////////////////////////////////////////////////////////////////
// Custom defines
///////////////////////////////////////////////////////////////////////////////

#define ENCODER_PIN_9 PA9
#define ENCODER_PIN_10 PA10
#define PPR 408             // Pulses Per Rev
#define CPR (4 * PPR)       // Counts Per Rev
#define DELAY_TIM TIM16

#endif // MAIN_H