// DS1722.c
// Angela Zheng
// angzheng@hmc.edu
// 10/22/2026
// Driver for the DS1722 digital thermometer over SPI, sets resolution
// and reads temperature registers.

#include "DS1722.h"
#include "STM32L432KC_SPI.h"
#include "STM32L432KC_GPIO.h"

// One SPI transaction
static uint8_t ds1722Transfer(uint8_t addr, uint8_t data) {
  digitalWrite(SPI_CE, PIO_HIGH); // chip enable
  spiSendReceive(addr); // send the address
  uint8_t result = spiSendReceive(data); // send or receive one byte
  digitalWrite(SPI_CE, PIO_LOW);  // disable
  return result;
}

void initDS1722(int resolution) {
  // resolution - 8 (000 = 8-bit ... 100 = 12-bit).
  uint8_t config = DS1722_CONFIG_BASE | ((resolution - 8) << 1);
  ds1722Transfer(DS1722_CONFIG_WRITE, config);
}

int16_t readTempRaw(void) {
  uint8_t msb = ds1722Transfer(DS1722_TEMP_MSB, 0x00);
  uint8_t lsb = ds1722Transfer(DS1722_TEMP_LSB, 0x00);
  return (int16_t) ((msb << 8) | lsb);
}
