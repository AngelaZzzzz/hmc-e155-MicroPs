/*
File: main.c
Author: Angela Zheng (starter code by Josh Brake)
Email: angzheng@hmc.edu
Date: 10/22/2026
Hosts an IoT webpage through the ESP8266 that toggles the LED on PA6,
displays room temperature read from DS1722 temperature over SPI, and sets the sensor resolution.
*/


#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include "main.h"

/////////////////////////////////////////////////////////////////
// Provided Constants and Functions
/////////////////////////////////////////////////////////////////

//Defining the web page in two chunks: everything before the current time, and everything after the current time
char* webpageStart = "<!DOCTYPE html><html><head><title>E155 Temperature Viewer and LED Controller</title>\
	<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\
	</head>\
	<body><h1>E155 Temperature Viewer and LED Controller</h1>";
char* ledStr = "<p>LED Control:</p><form action=\"ledon\"><input type=\"submit\" value=\"Turn the LED on!\"></form>\
	<form action=\"ledoff\"><input type=\"submit\" value=\"Turn the LED off!\"></form>";
char* resStr = "<p>Temperature Resolution:</p>\
	<form action=\"res8\" style=\"display:inline\"><input type=\"submit\" value=\"8-bit\"></form>\
	<form action=\"res9\" style=\"display:inline\"><input type=\"submit\" value=\"9-bit\"></form>\
	<form action=\"res10\" style=\"display:inline\"><input type=\"submit\" value=\"10-bit\"></form>\
	<form action=\"res11\" style=\"display:inline\"><input type=\"submit\" value=\"11-bit\"></form>\
	<form action=\"res12\" style=\"display:inline\"><input type=\"submit\" value=\"12-bit\"></form>";
char* webpageEnd   = "</body></html>";

//determines whether a given character sequence is in a char array request, returning 1 if present, -1 if not present
int inString(char request[], char des[]) {
	if (strstr(request, des) != NULL) {return 1;}
	return -1;
}

int updateLEDStatus(char request[])
{
	int led_status = 0;
	// The request has been received. now process to determine whether to turn the LED on or off
	if (inString(request, "ledoff")==1) {
		digitalWrite(LED_PIN, PIO_LOW);
		led_status = 0;
	}
	else if (inString(request, "ledon")==1) {
		digitalWrite(LED_PIN, PIO_HIGH);
		led_status = 1;
	}

	return led_status;
}

/////////////////////////////////////////////////////////////////
// Solution Functions
/////////////////////////////////////////////////////////////////

// Update resolution according to the new resolution input
int updateResolution(char request[])
{
	static int resolution = DEFAULT_RESOLUTION;
	int newRes = 0;

	// Check two-digit tags first so "res1x" is never misread
	if      (inString(request, "res10")==1) newRes = 10;
	else if (inString(request, "res11")==1) newRes = 11;
	else if (inString(request, "res12")==1) newRes = 12;
	else if (inString(request, "res8")==1)  newRes = 8;
	else if (inString(request, "res9")==1)  newRes = 9;

	if (newRes != 0) {
		resolution = newRes;
		initDS1722(resolution);
	}

	return resolution;
}

int main(void) {
  configureFlash();
  configureClock();

  gpioEnable(GPIO_PORT_A);
  gpioEnable(GPIO_PORT_B);
  gpioEnable(GPIO_PORT_C);

  pinMode(LED_PIN, GPIO_OUTPUT);
  
  RCC->APB2ENR |= (RCC_APB2ENR_TIM15EN);
  initTIM(TIM15);
  
  USART_TypeDef * USART = initUSART(USART1_ID, 125000);

  // Initialize SPI and DS1722
  initSPI(0b111, 0, 1);
  initDS1722(DEFAULT_RESOLUTION);

  while(1) {
    /* Wait for ESP8266 to send a request.
    Requests take the form of '/REQ:<tag>\n', with TAG begin <= 10 characters.
    Therefore the request[] array must be able to contain 18 characters.
    */

    // Receive web request from the ESP
    char request[BUFF_LEN] = "                  "; // initialize to known value
    int charIndex = 0;
  
    // Keep going until you get end of line character
    while(inString(request, "\n") == -1) {
      // Wait for a complete request to be transmitted before processing
      while(!(USART->ISR & USART_ISR_RXNE));
      request[charIndex++] = readChar(USART);
    }

    // Apply any resolution change, then read the temperature over SPI
    int resolution = updateResolution(request);
    float temp = readTempRaw() / 256.0f;

    // Show as many decimal places as the resolution provides
    char tempStr[48];
    if (resolution == 8)
      sprintf(tempStr, "%.0f &deg;C (8-bit resolution)", temp);
    else if (resolution == 9)
      sprintf(tempStr, "%.1f &deg;C (9-bit resolution)", temp);
    else if (resolution == 10)
      sprintf(tempStr, "%.2f &deg;C (10-bit resolution)", temp);
    else if (resolution == 11)
      sprintf(tempStr, "%.3f &deg;C (11-bit resolution)", temp);
    else
      sprintf(tempStr, "%.4f &deg;C (12-bit resolution)", temp);

    // Update string with current LED state
  
    int led_status = updateLEDStatus(request);

    char ledStatusStr[20];
    if (led_status == 1)
      sprintf(ledStatusStr,"LED is on!");
    else if (led_status == 0)
      sprintf(ledStatusStr,"LED is off!");

    // finally, transmit the webpage over UART
    sendString(USART, webpageStart); // webpage header code
    sendString(USART, ledStr); // button for controlling LED

    sendString(USART, "<h2>LED Status</h2>");


    sendString(USART, "<p>");
    sendString(USART, ledStatusStr);
    sendString(USART, "</p>");

    sendString(USART, "<h2>Temperature</h2>");
    sendString(USART, "<p>");
    sendString(USART, tempStr);
    sendString(USART, "</p>");

    sendString(USART, resStr); // buttons for selecting resolution

    sendString(USART, webpageEnd);
  }
}
