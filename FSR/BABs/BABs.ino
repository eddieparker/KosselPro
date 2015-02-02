/**
  * Brainwave Augmentation Board
  * The "Babs".
  *
  * Augment your brainwave board with the following:
  * 	- Better FSR handling (detects resting FSR pressure, triggers on average deviance)
  * 	- NeoPixel based on temperature
  * 		- Requires a yet-to-be-written patch to Marlin to I2C the temperature over.
  *
  *
  * TODO: 
  * 	- Setup I2C
  * 		- Ensure I can fake send temperature from another Arduino, light the LEDs
  *		- Setup the FSRs
  */

#include "BABs.h"

// FSR portion
int gFsrPins[] = { A0, A1, A2 };
int gFSRTriggeredPin = 12;

#define SHORT_TERM_SAMPLE_COUNT 8
#define LONG_TERM_SAMPLE_COUNT 16

#define LONG_TERM_SAMPLE_CAPTURE_TIME (2000 / LONG_TERM_SAMPLE_COUNT) // Every two seconds we want a fresh average.
int gLastLongTermSampleTime = 0;
int gLongTermSamples[3][LONG_TERM_SAMPLE_COUNT];
int gLongTermSampleIndex = 0;

int gShortTermSamples[3][SHORT_TERM_SAMPLE_COUNT];
int gShortSampleIndex = 0;

// NeoPixel items

unsigned long gLastNeoPixelMillis = 0;
int gLastTemperature = 0;
int gNeoPixelPin=3;
#include <Adafruit_NeoPixel.h>
Adafruit_NeoPixel gNeoPixelStrip = Adafruit_NeoPixel(60, gNeoPixelPin, NEO_GRB + NEO_KHZ800);

#define NEOPIXEL_EFFECT_SOLID_COLOR 0

#define NEOPIXEL_ERROR_PULSE_PERIOD (2 * 1000)
#define NEOPIXEL_PULSE_PERIOD 100
#define NEOPIXEL_PULSE_LOW_BRIGHTNESS 150
#define NEOPIXEL_PULSE_HIGH_BRIGHTNESS 255

// I2C 
#include "Wire.h"


void setup()
{
	gNeoPixelStrip.begin();
	gNeoPixelStrip.show(); // Set to off.

	Wire.begin(BABS_I2C_ADDRESS);
	Serial.begin(9600);
	pinMode(gFSRTriggeredPin, OUTPUT);

	int highestReading = 0;

	for(int i = 0; i < 3; ++i)
	{
		highestReading = max(analogRead(gFsrPins[i]), highestReading);
	}

	for(int i = 0; i < 3; ++i)
	{
		for(int j = 0; j < SHORT_TERM_SAMPLE_COUNT; ++j)
		{
			gShortTermSamples[i][j] = highestReading;
		}
	}

	for(int i = 0; i < 3; ++i)
	{
		for(int j = 0; j < LONG_TERM_SAMPLE_COUNT; ++j)
		{
			gLongTermSamples[i][j] = highestReading;
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
					gLastNeoPixelMillis = millis();
					byte mode = Wire.read();

					gLastTemperature = 0;

					int i = 0;

					while(Wire.available())
					{
						byte b = Wire.read();
						gLastTemperature = gLastTemperature | b << (i*8);
						Serial.print("(" + String(b) + ") ");
					}

					Serial.println("Received temp: " + String(gLastTemperature) + " How many: " + String(howMany));
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
  */
#define TEMPERATURE_INDEX 0
#define COLOUR_INDEX_R 1
#define COLOUR_INDEX_G 2
#define COLOUR_INDEX_B 3
uint8_t gColourLookUp[][4] = 
{
//	Temp	R    G    B
	{50, 	0,     0, 255},	// Blue
	{80, 	0,   255, 255},	// Cyan
	{110, 	0,   255,   0},	// Green
	{140,	255, 255,   0}, // Yellow
	{170,	255, 100,   0}, // Orange
	{200,	255,   0,   0}, // Red
};

int gSizeOfColourLookUp = sizeof(gColourLookUp)/4/sizeof(uint8_t);

void PrintColourLookUpData(String name, uint8_t* pColourData)
{
	Serial.print(name + ": (" + pColourData[COLOUR_INDEX_R] + ", " + pColourData[COLOUR_INDEX_G] + ", " + pColourData[COLOUR_INDEX_B] + ")\n");
}

uint32_t GetColourForTemperature(int temperature)
{
	uint8_t *pPreviousData = gColourLookUp[TEMPERATURE_INDEX];
	uint8_t *pNextData = gColourLookUp[gSizeOfColourLookUp-1];

	for(int i = 0; i < gSizeOfColourLookUp; ++i)
	{
		if(gColourLookUp[i][TEMPERATURE_INDEX] > temperature)
		{
			break;
		}

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

	temperature = constrain( temperature, pPreviousData[TEMPERATURE_INDEX], pNextData[TEMPERATURE_INDEX]);

	int r = pPreviousData[COLOUR_INDEX_R];
	int g = pPreviousData[COLOUR_INDEX_G];
	int b = pPreviousData[COLOUR_INDEX_B];

	// If you don't guard against this, you get divide by zero blamminess.
	if(pPreviousData[TEMPERATURE_INDEX] != pNextData[TEMPERATURE_INDEX])
	{
		r = map(temperature, pPreviousData[TEMPERATURE_INDEX], pNextData[TEMPERATURE_INDEX], pPreviousData[COLOUR_INDEX_R], pNextData[COLOUR_INDEX_R]);
		g = map(temperature, pPreviousData[TEMPERATURE_INDEX], pNextData[TEMPERATURE_INDEX], pPreviousData[COLOUR_INDEX_G], pNextData[COLOUR_INDEX_G]);
		b = map(temperature, pPreviousData[TEMPERATURE_INDEX], pNextData[TEMPERATURE_INDEX], pPreviousData[COLOUR_INDEX_B], pNextData[COLOUR_INDEX_B]);
	}

/*
	PrintColourLookUpData("Prev: ", pPreviousData);
	PrintColourLookUpData("Next: ", pNextData);
	*/

	//Serial.println("T: " + String(temperature) + " " + String(pPreviousData[TEMPERATURE_INDEX]) + " " + String(pNextData[TEMPERATURE_INDEX]) + " " + pPreviousData[COLOUR_INDEX_B] + " " + pNextData[COLOUR_INDEX_B]);

	uint32_t colour = Adafruit_NeoPixel::Color(r,g,b);

	return colour;
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
				uint8_t brightness = map(sin(millis()/NEOPIXEL_PULSE_PERIOD)*100, -100, 100, NEOPIXEL_PULSE_LOW_BRIGHTNESS, NEOPIXEL_PULSE_HIGH_BRIGHTNESS);
				gNeoPixelStrip.setBrightness(brightness);

				uint32_t colour = GetColourForTemperature(temperature);
				for(int i = 0; i < gNeoPixelStrip.numPixels(); ++i)
				{
					gNeoPixelStrip.setPixelColor(i, colour);
				}
				gNeoPixelStrip.show();
			}
			break;
	}
}

void SetFSRTriggered(bool bTriggered)
{
	//digitalWrite(gFSRTriggeredPin, bTriggered ? HIGH : LOW);
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
	bool bFsrTriggered = false;
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

		bool bThisFSRTriggered = fsrReading > longTermAverage;

		if(bThisFSRTriggered)
		{
			//Serial.println("FSR " + String(fsrIndex) + " triggered.  Reading: " + String(fsrReading) + " versus: " + String(longTermAverage));
		}

		bFsrTriggered |= bThisFSRTriggered;
	}
	//SetFSRTriggered(bFsrTriggered);
	SetFSRTriggered(true);
}

void DoUpdateNeoPixel()
{
	unsigned long time = millis();
	unsigned long delta = time - gLastNeoPixelMillis;
	if(delta > 10000)
	{
		//Serial.println("In error mode: nobody's talked to me in a while.");
		uint8_t brightness = map(sin(millis()/NEOPIXEL_PULSE_PERIOD)*100, -100, 100, NEOPIXEL_PULSE_LOW_BRIGHTNESS, NEOPIXEL_PULSE_HIGH_BRIGHTNESS);
		gNeoPixelStrip.setBrightness(brightness);

		uint32_t colourOn = Adafruit_NeoPixel::Color(255,0,0);
		uint32_t colourOff = Adafruit_NeoPixel::Color(255,255,255);

		for(int i = 0; i < gNeoPixelStrip.numPixels(); ++i)
		{
			gNeoPixelStrip.setPixelColor(i, i%2 ? colourOn : colourOff);
		}

		gNeoPixelStrip.show();
	}
	else
	{
		SetNeoPixelsTemperature(gLastTemperature, NEOPIXEL_EFFECT_SOLID_COLOR);
	}
}


void loop()
{
	DoFSRTriggeringTests();
	DoUpdateNeoPixel();
	digitalWrite(gFSRTriggeredPin, HIGH);
}
