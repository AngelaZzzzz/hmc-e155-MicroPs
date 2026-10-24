// DS1722.h
// Angela Zheng
// angzheng@hmc.edu
// 10/22/2026
// Header for the DS1722 SPI digital thermometer driver.

#ifndef DS1722_H
#define DS1722_H

#include <stdint.h>

///////////////////////////////////////////////////////////////////////////////
// Definitions
///////////////////////////////////////////////////////////////////////////////

// Register addresses
#define DS1722_CONFIG_READ  0x00
#define DS1722_CONFIG_WRITE 0x80
#define DS1722_TEMP_LSB     0x01
#define DS1722_TEMP_MSB     0x02
#define DS1722_CONFIG_BASE  0xE0

///////////////////////////////////////////////////////////////////////////////
// Function prototypes
///////////////////////////////////////////////////////////////////////////////

/* Configures the DS1722 for continuous conversion at the given resolution.
 *    -- resolution: 8, 9, 10, 11, or 12 bits */
void initDS1722(int resolution);

/* Reads the temperature register as a signed 16-bit value.
 * The MSB is the integer part in degrees C and the LSB holds
 * the fractional bits, so degrees C = raw / 256. */
int16_t readTempRaw(void);

#endif
