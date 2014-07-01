/**
  * Brainwave Augmentation Board
  * The "Babs".
  *
  * Augment your brainwave board with the following:
  * 	- Better FSR handling (detects resting FSR pressure, triggers on average deviance)
  * 	- NeoPixel based on temperature
  * 		- Requires a yet-to-be-written patch to Marlin to I2C the temperature over.
  */
// FSR portion
int gFsrPins[] = { A0, A1, A2 };
int gFSRTriggeredPin = 13;

#define SHORT_TERM_SAMPLE_COUNT 8
#define LONG_TERM_SAMPLE_COUNT 16

#define LONG_TERM_SAMPLE_CAPTURE_TIME (2000 / LONG_TERM_SAMPLE_COUNT) // Every two seconds we want a fresh average.
int gLastLongTermSampleTime = 0;
int gLongTermSamples[3][LONG_TERM_SAMPLE_COUNT];
int gLongTermSampleIndex = 0;

int gShortTermSamples[3][SHORT_TERM_SAMPLE_COUNT];
int gShortSampleIndex = 0;

// NeoPixel items
int gNeoPixelPin=2;
#include <Adafruit_NeoPixel.h>
Adafruit_NeoPixel gNeoPixelStrip = Adafruit_NeoPixel(60, gNeoPixelPin, NEO_GRB + NEO_KHZ800);

#define HEATING_MODE_NONE 0
#define HEATING_MODE_HEATING 1
#define HEATING_MODE_COOLING 2

#define NEOPIXEL_EFFECT_SOLID_COLOR 0
#define NEOPIXEL_EFFECT_PULSE_TO_HIGH 1
#define NEOPIXEL_EFFECT_PULSE_TO_LOW 2

// I2C 
#include "Wire.h"

#define WIRE_MESSAGE_TEMPERATURE 0

#define BABS_I2C_ADDRESS 0x01 

void setup()
{
	gNeoPixelStrip.begin();
	gNeoPixelStrip.show(); // Set to off.

	Wire.begin(BABS_I2C_ADDRESS);
	Serial.begin(9600);
	pinMode(gFSRTriggeredPin, OUTPUT);

	for(int i = 0; i < 3; ++i)
	{
		for(int j = 0; j < SHORT_TERM_SAMPLE_COUNT; ++j)
		{
			gShortTermSamples[i][j] = 0;
		}
	}

	for(int i = 0; i < 3; ++i)
	{
		for(int j = 0; j < LONG_TERM_SAMPLE_COUNT; ++j)
		{
			gLongTermSamples[i][j] = 0;
		}
	}

	gLastLongTermSampleTime = millis();

	Wire.onReceive(OnReceived);
}

void OnReceived(int howMany)
{
	while(Wire.available())
	{
		byte message = Wire.read();

		switch(message)
		{
			case WIRE_MESSAGE_TEMPERATURE:
				{
					byte mode = Wire.read();
					int temperature = Wire.read();
					temperature = Wire.read() << 8;
					SetNeoPixelsTemperature(temperature, mode);
				}
				break;
			default:
				Serial.println("Unhandled case: " + String(message));
				break;
		}
	}
}

/**
  * The minimum degrees celcius as the first in the pair, and the colour to start the lerp from
  * in the second.
  *
  * Will be clamped on either side.
  *
  * TODO: Have more colours.
  */
#define TEMPERATURE_INDEX 0
#define COLOUR_INDEX 1
uint32_t gColourLookUp[][2] = 
{
	{25, Adafruit_NeoPixel::Color(0,0,255)},
	{100, Adafruit_NeoPixel::Color(255,255,0)},
	{200, Adafruit_NeoPixel::Color(255,0,0)},
};

int gSizeOfColourLookUp = sizeof(gColourLookUp)/2/sizeof(uint32_t);

uint32_t Lerp(uint32_t from, uint32_t to, float alpha)
{
	return (to-from)*alpha+from;
}

uint32_t GetColourForTemperature(int temperature)
{
	uint32_t *pPreviousData = gColourLookUp[TEMPERATURE_INDEX];
	uint32_t *pNextData = gColourLookUp[gSizeOfColourLookUp-1];

	for(int i = 0; i < gSizeOfColourLookUp; ++i)
	{
		if(gColourLookUp[i][TEMPERATURE_INDEX] < temperature)
		{
			// We may have our previous value.
			pPreviousData = gColourLookUp[i];
			
			if(i+1 < gSizeOfColourLookUp)
			{
				if(gColourLookUp[i+1][TEMPERATURE_INDEX] >= temperature)
				{
					pNextData = gColourLookUp[i+1];
					break;
				}
			}
		}
	}

	float temperatureRange = pNextData[TEMPERATURE_INDEX]-pPreviousData[TEMPERATURE_INDEX];
	float alpha = constrain( (temperature - pPreviousData[TEMPERATURE_INDEX]) / temperatureRange, 0, 1);

	return Lerp(pPreviousData[COLOUR_INDEX], pNextData[COLOUR_INDEX], alpha);
}

/**
  * Set the neo pixels according to colour. 
  */
void SetNeoPixelsTemperature(int temperature, byte effect)
{
	switch(effect)
	{
		default:
			Serial.println("Unsupported effect " + String(effect) + " requested.  Defaulting to NEOPIXEL_EFFECT_SOLID_COLOR.");
		case NEOPIXEL_EFFECT_SOLID_COLOR:
			{
				uint32_t colour = GetColourForTemperature(temperature);
				for(int i = 0; i < gNeoPixelStrip.numPixels(); ++i)
				{
					gNeoPixelStrip.setPixelColor(i, colour);
				}
			}
			break;
	}
}

void SetFSRTriggered(bool bTriggered)
{
	digitalWrite(gFSRTriggeredPin, bTriggered ? HIGH : LOW);
}

void UpdateLongTermAverage()
{
	int time = millis();

	if(time - gLastLongTermSampleTime < LONG_TERM_SAMPLE_CAPTURE_TIME)
	{
		return;
	}

	gLastLongTermSampleTime = time;

	int shortTermAverages[] = { 0, 0, 0};

	for(int i = 0; i < 3; ++i)
	{
		for(int j = 0; j < SHORT_TERM_SAMPLE_COUNT; ++j)
		{
			shortTermAverages[i] += gShortTermSamples[i][j];
		}

		shortTermAverages[i] /= SHORT_TERM_SAMPLE_COUNT;
	}

	for(int i = 0; i < 3; ++i)
	{
		gLongTermSamples[i][gLongTermSampleIndex] = shortTermAverages[i];
	}

	gLongTermSampleIndex++;

	if(gLongTermSampleIndex > LONG_TERM_SAMPLE_COUNT)
	{
		gLongTermSampleIndex = 0;
	}
}

int GetLongTermAverage(int fsrIndex)
{
	int average = 0;

	for(int i = 0; i < LONG_TERM_SAMPLE_COUNT; ++i)
	{
		average += gLongTermSamples[fsrIndex][i];
	}

	return average / LONG_TERM_SAMPLE_COUNT;
}

void DoFSRTriggeringTests()
{
	bool fsrTriggered = false;
	for(int fsrIndex = 0; fsrIndex < 3; ++fsrIndex)
	{
		int fsrReading = analogRead(gFsrPins[fsrIndex]);

		gShortTermSamples[fsrIndex][gShortSampleIndex++] = fsrReading;

		if(gShortSampleIndex >= SHORT_TERM_SAMPLE_COUNT)
		{
			gShortSampleIndex = 0;
			UpdateLongTermAverage();
		}

		int longTermAverage = GetLongTermAverage(fsrIndex);

		Serial.print("FSR " + (String)fsrIndex + ": " + (String)longTermAverage + " versus ");
		Serial.println(fsrReading);

		fsrTriggered |= (longTermAverage < fsrReading);
	}
	SetFSRTriggered(fsrTriggered);
}


void loop()
{
	DoFSRTriggeringTests();
}
