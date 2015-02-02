#include "Wire.h"

// I2C jazz
#define BABS_I2C_ADDRESS 0x01 
#define WIRE_MESSAGE_TEMPERATURE 0

#define HEATING_MODE_NONE 0
#define HEATING_MODE_HEATING 1
#define HEATING_MODE_COOLING 2

void setup()
{
	Wire.begin();
	Serial.begin(9600);
}

int16_t gTemperature = 0;
void loop()
{
	Wire.beginTransmission(BABS_I2C_ADDRESS);
		Wire.write(WIRE_MESSAGE_TEMPERATURE);	
		Wire.write(HEATING_MODE_NONE);
		Wire.write((byte*)(&gTemperature), sizeof(int16_t));
	Wire.endTransmission();

	if(gTemperature++ > 250)
	{
		gTemperature = 0;
	}

	Serial.println("Sending: " + String(gTemperature));

	delay(250);
}
