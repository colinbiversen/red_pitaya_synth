

/**
 * main.c
 */
#include <stdint.h>
#include <stdbool.h>

#include "inc/hw_memmap.h"       // Peripheral base addresses
#include "inc/hw_types.h"        // For register access/macros (optional)
#include "driverlib/sysctl.h"    // Clock and peripheral control
#include "driverlib/gpio.h"      // GPIO input for buttons
#include "driverlib/ssi.h"       // SPI/SSI peripheral
#include "driverlib/debug.h"     // Debug peripheral
#include "driverlib/pin_map.h"

#ifdef DEBUG
void
__error__(char *pcFilename, uint32_t ui32Line)
{
    while(1);
}
#endif

//
// struct for keyboard button mapping
//

typedef struct {
    uint32_t portBase;
    uint8_t pin;
    const char* name;
} DigitalInput;

DigitalInput inputPins[25] = {
    {GPIO_PORTB_BASE, GPIO_PIN_0, "Input_0  (PB0)"},
    {GPIO_PORTB_BASE, GPIO_PIN_1, "Input_1  (PB1)"},
    {GPIO_PORTB_BASE, GPIO_PIN_2, "Input_2  (PB2)"},
    {GPIO_PORTB_BASE, GPIO_PIN_3, "Input_3  (PB3)"},
    {GPIO_PORTB_BASE, GPIO_PIN_4, "Input_4  (PB4)"},
    {GPIO_PORTB_BASE, GPIO_PIN_5, "Input_5  (PB5)"},
    {GPIO_PORTB_BASE, GPIO_PIN_6, "Input_6  (PB6)"},
    {GPIO_PORTB_BASE, GPIO_PIN_7, "Input_7  (PB7)"},

    {GPIO_PORTE_BASE, GPIO_PIN_0, "Input_8  (PE0)"},
    {GPIO_PORTE_BASE, GPIO_PIN_1, "Input_9  (PE1)"},
    {GPIO_PORTE_BASE, GPIO_PIN_2, "Input_10 (PE2)"},
    {GPIO_PORTE_BASE, GPIO_PIN_3, "Input_11 (PE3)"},
    {GPIO_PORTE_BASE, GPIO_PIN_4, "Input_12 (PE4)"},
    {GPIO_PORTE_BASE, GPIO_PIN_5, "Input_13 (PE5)"},

    {GPIO_PORTF_BASE, GPIO_PIN_1, "Input_14 (PF1)"},
    {GPIO_PORTF_BASE, GPIO_PIN_2, "Input_15 (PF2)"},
    {GPIO_PORTF_BASE, GPIO_PIN_3, "Input_16 (PF3)"},
    {GPIO_PORTF_BASE, GPIO_PIN_4, "Input_17 (PF4)"},

    {GPIO_PORTD_BASE, GPIO_PIN_0, "Input_18 (PD0)"},
    {GPIO_PORTD_BASE, GPIO_PIN_1, "Input_19 (PD1)"},
    {GPIO_PORTD_BASE, GPIO_PIN_2, "Input_20 (PD2)"},
    {GPIO_PORTD_BASE, GPIO_PIN_3, "Input_21 (PD3)"},

    {GPIO_PORTC_BASE, GPIO_PIN_4, "Input_22 (PC4)"},
    {GPIO_PORTC_BASE, GPIO_PIN_5, "Input_23 (PC5)"},
    {GPIO_PORTC_BASE, GPIO_PIN_6, "Input_24 (PC6)"},
    // PC7 is still available if needed
};


//
// Function prototypes
//
void SPI0Init(void);
void keyboardInit(void);
void SPISend(uint32_t SPIWord);
uint8_t pinToIndex(uint8_t pinMask);
uint32_t getKeyPress(void);



//
// main function
//
int main(void){

    SPI0Init();
    keyboardInit();


    while (1) {
        uint32_t spiWord = 0x00000000;
        spiWord = getKeyPress();

        SPISend(spiWord);
    }
}


//
// Initializes SSI0 SPI peripheral
//
void SPI0Init(void){

    //
    // Enable the SSI0 Peripheral
    //
    SysCtlPeripheralEnable(SYSCTL_PERIPH_SSI0);
    while(!SysCtlPeripheralReady(SYSCTL_PERIPH_SSI0))
    {
    }

    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOA);
    while(!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOA))
    {
    }
    GPIOPinConfigure(GPIO_PA2_SSI0CLK);
    GPIOPinConfigure(GPIO_PA3_SSI0FSS);
    GPIOPinConfigure(GPIO_PA4_SSI0RX);
    GPIOPinConfigure(GPIO_PA5_SSI0TX);
    GPIOPinTypeSSI(GPIO_PORTA_BASE, 0b00111100);


    SSIConfigSetExpClk(
            SSI0_BASE,              // ui32Base
            SysCtlClockGet(),       // ui32SSIClk
            SSI_FRF_MOTO_MODE_0,    // ui32Protocol
            SSI_MODE_SLAVE,         // ui32Mode
            1000000,                // ui32BitRate
            16                      // ui32DataWidth
    );

    SSIEnable(SSI0_BASE);

}


//
// Initializes all of the GPIO for digital read of keyboard buttons
//
void keyboardInit(void){

    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOA);
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOB);
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOC);
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOD);
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOE);
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOF);

    // Optional: Wait for peripherals to be ready
    while (!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOA)) {}
    while (!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOB)) {}
    while (!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOC)) {}
    while (!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOD)) {}
    while (!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOE)) {}
    while (!SysCtlPeripheralReady(SYSCTL_PERIPH_GPIOF)) {}

    for (int i = 0; i < 25; i++){
        GPIOPinTypeGPIOInput(inputPins[i].portBase, inputPins[i].pin); // Initializing as inputs based on struct
    }
}



void SPISend(uint32_t SPIWord){

    uint16_t SPIWordLow = SPIWord & ~0xFFFF0000;
    uint16_t SPIWordHigh = ((SPIWord & 0xFFFF0000) >> 16);

    if (SSIBusy(SSI0_BASE) == false) {
        SSIDataPutNonBlocking(SSI0_BASE,SPIWordLow);
        SSIDataPutNonBlocking(SSI0_BASE,SPIWordHigh);
    }
}


//
// Builds keyboard presses into a SPI-friendly 32-bit word
//
uint32_t getKeyPress(void) {
    uint32_t keyPress = 0;

    for (int i = 0; i < 25; i++) {
        int32_t pinValue = GPIOPinRead(inputPins[i].portBase, inputPins[i].pin);
        uint8_t pinNum = pinToIndex(inputPins[i].pin);  // Get actual pin number (0–7)
        keyPress |= (((pinValue >> pinNum) & 1) << i);     // Place into correct bit of keyPress
    }

    // Clear bits [31:25], just in case
    keyPress &= ~0xFE000000;

    return keyPress;
}

uint8_t pinToIndex(uint8_t pinMask) {
    uint8_t i = 0;
    while (!(pinMask & 1)) {
        pinMask >>= 1;
        i++;
    }
    return i;
}










