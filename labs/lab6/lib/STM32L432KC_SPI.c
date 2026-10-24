// STM32L432KC_SPI.c
// Angela Zheng
// angzheng@hmc.edu
// 10/22/2026
// SPI1 driver, configures SPI1 as an 8-bit master on PB3/PB4/PB5 with a chip enable on PB1.

#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"
#include "STM32L432KC_RCC.h"

void initSPI(int br, int cpol, int cpha) {
  // Enable clocks for GPIOB and SPI1 (SPI1 lives on APB2)
  RCC->AHB2ENR |= RCC_AHB2ENR_GPIOBEN;
  RCC->APB2ENR |= RCC_APB2ENR_SPI1EN;

  // set SCK, MISO, MOSI to alternate function 5
  pinMode(SPI_SCK, GPIO_ALT);
  pinMode(SPI_MISO, GPIO_ALT);
  pinMode(SPI_MOSI, GPIO_ALT);
  GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL3, 5);
  GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL4, 5);
  GPIOB->AFR[0] |= _VAL2FLD(GPIO_AFRL_AFSEL5, 5);

  // set chip enable to output
  pinMode(SPI_CE, GPIO_OUTPUT);

  // set speed to high for SCK (PB3)
  GPIOB->OSPEEDR |= GPIO_OSPEEDR_OSPEED3;

  // disable SPI while configuring
  SPI1->CR1 &= ~SPI_CR1_SPE;

  // CR1 configurations
  SPI1->CR1 = _VAL2FLD(SPI_CR1_BR, br); // set baud rate
  SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPOL, cpol); // set clock polarity
  SPI1->CR1 |= _VAL2FLD(SPI_CR1_CPHA, cpha); // set clock phase
  SPI1->CR1 |= SPI_CR1_MSTR | SPI_CR1_SSM | SPI_CR1_SSI;
  SPI1->CR1 &= ~SPI_CR1_LSBFIRST; // set MSB first

  // CR2 configurations
  SPI1->CR2 = _VAL2FLD(SPI_CR2_DS, 0b0111); // set data size to be a char
  SPI1->CR2 |= SPI_CR2_FRXTH;

  // enable SPI
  SPI1->CR1 |= SPI_CR1_SPE;
}

char spiSendReceive(char send) {
  // Wait until the transmit buffer is empty
  while (!(SPI1->SR & SPI_SR_TXE));

  // Treat DR as 8 bits so only one byte is transferred
  *((volatile uint8_t *) &SPI1->DR) = send;

  // Wait until the received byte is available
  while (!(SPI1->SR & SPI_SR_RXNE));

  uint8_t character = *((volatile uint8_t *) &SPI1->DR);

  return character;
}
