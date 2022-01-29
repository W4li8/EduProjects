/* 
 * "Small Hello World" example. 
 * 
 * This example prints 'Hello from Nios II' to the STDOUT stream. It runs on
 * the Nios II 'standard', 'full_featured', 'fast', and 'low_cost' example 
 * designs. It requires a STDOUT  device in your system's hardware. 
 *
 * The purpose of this example is to demonstrate the smallest possible Hello 
 * World application, using the Nios II HAL library.  The memory footprint
 * of this hosted application is ~332 bytes by default using the standard 
 * reference design.  For a more fully featured Hello World application
 * example, see the example titled "Hello World".
 *
 * The memory footprint of this example has been reduced by making the
 * following changes to the normal "Hello World" example.
 * Check in the Nios II Software Developers Manual for a more complete 
 * description.
 * 
 * In the SW Application project (small_hello_world):
 *
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 * In System Library project (small_hello_world_syslib):
 *  - In the C/C++ Build page
 * 
 *    - Set the Optimization Level to -Os
 * 
 *    - Define the preprocessor option ALT_NO_INSTRUCTION_EMULATION 
 *      This removes software exception handling, which means that you cannot 
 *      run code compiled for Nios II cpu with a hardware multiplier on a core 
 *      without a the multiply unit. Check the Nios II Software Developers 
 *      Manual for more details.
 *
 *  - In the System Library page:
 *    - Set Periodic system timer and Timestamp timer to none
 *      This prevents the automatic inclusion of the timer driver.
 *
 *    - Set Max file descriptors to 4
 *      This reduces the size of the file handle pool.
 *
 *    - Check Main function does not exit
 *    - Uncheck Clean exit (flush buffers)
 *      This removes the unneeded call to exit when main returns, since it
 *      won't.
 *
 *    - Check Don't use C++
 *      This builds without the C++ support code.
 *
 *    - Check Small C library
 *      This uses a reduced functionality C library, which lacks  
 *      support for buffering, file IO, floating point and getch(), etc. 
 *      Check the Nios II Software Developers Manual for a complete list.
 *
 *    - Check Reduced device drivers
 *      This uses reduced functionality drivers if they're available. For the
 *      standard design this means you get polled UART and JTAG UART drivers,
 *      no support for the LCD driver and you lose the ability to program 
 *      CFI compliant flash devices.
 *
 *    - Check Access device drivers directly
 *      This bypasses the device file system to access device drivers directly.
 *      This eliminates the space required for the device file system services.
 *      It also provides a HAL version of libc services that access the drivers
 *      directly, further reducing space. Only a limited number of libc
 *      functions are available in this configuration.
 *
 *    - Use ALT versions of stdio routines:
 *
 *           Function                  Description
 *        ===============  =====================================
 *        alt_printf       Only supports %s, %x, and %c ( < 1 Kbyte)
 *        alt_putstr       Smaller overhead than puts with direct drivers
 *                         Note this function doesn't add a newline.
 *        alt_putchar      Smaller overhead than putchar with direct drivers
 *        alt_getchar      Smaller overhead than getchar with direct drivers
 *
 */

#include "sys/alt_stdio.h"

//#include "led_matrix_update.cpp"
#include "led_control.h"
#include <system.h>
void setup(){
	LedControl lc=LedControl(DIN,CLK,CS,1);

    lc.shutdown(0,false);
    lc.setIntensity(0,3);      //Adjust the brightness maximum is 15
    lc.clearDisplay(0);
    lc.setLed(0, 3, 4, 1);
//    while(1)
    for(int i(0); i < 8; i++) {
        for(int j(0); j < 8; j++) {
          lc.setLed(0, i, j, 1);
          lc.setLed(0, 7-i, 7-j, 1);
          for(int i(0); i < 10000; i++);
          lc.clearDisplay(0);
        }
    }
}
int main()
{ 
  alt_putstr("Hello from Nios II!\n");
//  IOWR_8DIRECT(GPIO_0, IREGDIR, MODE_ALL_OUTPUT);
//  IOWR_8DIRECT(GPIO_0, IREGPORTSET, 0b110);

//  setup();
//  IOWR(GPIO_0, 1, 0xFFFFFFFF); // mode all output
//  IOWR(GPIO_0,4,0x0);
//  IOWR(GPIO_0,4,0x1);
//  IOWR(GPIO_0,0,0x2);
//  setup();
  IOWR_8DIRECT(PARALLEL_PORT_0_BASE, 0, 0xFF); // mode all output
  IOWR_8DIRECT(PARALLEL_PORT_0_BASE, 2, 0xFF); // mode all output
while(1);
//  setup();
  /* Event loop never exits. */
  while (1) {
	  digitalWrite(0,1);
	  digitalWrite(1,1);
	  digitalWrite(2,1);
	    for(int i=0;i<100000;i++);
		  digitalWrite(0,0);
		  digitalWrite(1,0);
		  digitalWrite(2,0);
		    for(int i=0;i<100000;i++);

  }

  return 0;
}
