#include <io.h>
#include <system.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/alt_irq.h>
#include <altera_avalon_performance_counter.h>
#include <altera_avalon_mutex.h>
#include <altera_avalon_mutex_regs.h>
#include <altera_avalon_timer.h>
#include <altera_avalon_timer_regs.h>
#include <altera_avalon_mailbox_simple.h>
#include <altera_avalon_mailbox_simple_regs.h>
#include "led_control.h"
#include <sys/alt_cache.h>
#include <inttypes.h>

//#define nomatrix // for when we dont have a LED matrix to run it on
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c\n"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? (unsigned char)(178) : 'O'),	\
    (byte & 0x40 ?( unsigned char)(178) : 'O'),		\
    (byte & 0x20 ?(unsigned  char)(178) : 'O'),		\
    (byte & 0x10 ?( unsigned char)(178) : 'O'),		\
    (byte & 0x08 ?( unsigned char)(178) : 'O'),		\
    (byte & 0x04 ?( unsigned char)(178) : 'O'),		\
    (byte & 0x02 ?( unsigned char)(178) : 'O'),		\
    (byte & 0x01 ?( unsigned char)(178) : 'O') 

/* Memory access control */
volatile uint8_t* game_status;
volatile uint8_t* computer_score;
volatile uint8_t* player_score;
volatile uint8_t * world_map; 		

alt_mutex_dev* mutti;


/* Led matrix object pointer */
static LedControl* ledmatrix;

// Faces //
static byte happyfull[8] = {0x3C,0x42,0x99,0xA5,0x81,0xA5,0x42,0x3C};
static byte sadfull[8]   = {0x3C,0x42,0xA5,0x99,0x81,0xA5,0x42,0x3C};
static byte happy[8]   = {0x00,0x00,0x18,0x24,0x00,0x24,0x00,0x00};
static byte neutral[8] = {0x00,0x00,0x00,0x3c,0x00,0x24,0x00,0x00};
static byte sad[8]     = {0x00,0x00,0x24,0x18,0x00,0x24,0x00,0x00};

// Utility function to display game winner once maximum score is reached //
static void display_endgame(LedControl& ledmatrix, byte endgame[8]) {
	for(int i(0); i < 8 ; i++) {
		ledmatrix.setRow(0, i, endgame[i]);
		printf(BYTE_TO_BINARY_PATTERN,(uint8_t)BYTE_TO_BINARY(endgame[i]));
	}
}

// Utility function to display game status smiley & score //
static void display_status(LedControl& ledmatrix, byte status[8]) {
  
	for(int i(0); i < 8 ; i++) {
		switch(i) {
		  case 0:
			ledmatrix.setRow(0, i, (byte)IORD_8DIRECT(player_score, 0));
#ifdef nomatrix
		printf(BYTE_TO_BINARY_PATTERN,(uint8_t)BYTE_TO_BINARY(*player_score));
#endif
			break;
		  case 7:
			ledmatrix.setRow(0, i, (byte)IORD_8DIRECT(computer_score, 0));
#ifdef nomatrix
		printf(BYTE_TO_BINARY_PATTERN,(uint8_t)BYTE_TO_BINARY(*computer_score));
#endif
			break;
		  default:
			ledmatrix.setRow(0, i, status[i]);
#ifdef nomatrix
		printf(BYTE_TO_BINARY_PATTERN,(uint8_t)BYTE_TO_BINARY(status[i]));
#endif
		}
	}
}

// Utility function to display game world //
static void display_world(LedControl& ledmatrix) {
	for(int i(0); i < 8 ; i++) {
		ledmatrix.setRow(0, i, (byte)IORD_8DIRECT(world_map, i));
#ifdef nomatrix
		printf(BYTE_TO_BINARY_PATTERN,(uint8_t)BYTE_TO_BINARY(world_map[i]));
#endif
	}
}

int measuring = 1;
// Led matrix refresh ISR // 
static void refresh_isr(void* context) {
  if(measuring )
      PERF_BEGIN(PERFORMANCE_COUNTER_0_BASE, 1);

  /**flush all relevant datacache to have secure reads.**/
// acknowledge interrupt
	IOWR_ALTERA_AVALON_TIMER_STATUS(TIMER_0_BASE, 0b10);
	alt_dcache_flush((void*)world_map,8);
	alt_dcache_flush((void*)game_status,1);
	alt_dcache_flush((void*)computer_score,1);
	alt_dcache_flush((void*)player_score,1);
  

	altera_avalon_mutex_lock(mutti, 1);
	switch(IORD_8DIRECT(game_status, 0)) {
	  case 'p':
		display_status(*ledmatrix, happy);
		break;
	  case 'P':
		display_endgame(*ledmatrix, happyfull);
		break;
	  case 'c':
		display_status(*ledmatrix, sad);
		break;
	  case 'C':
		display_endgame(*ledmatrix, sadfull);
		break;
	  case 'd':
		display_status(*ledmatrix, neutral);
		break;
	  case 'W':
		display_world(*ledmatrix);
		break;
	  default:
		ledmatrix->clearDisplay(0);
	}
	altera_avalon_mutex_unlock(mutti);
  if(measuring)
      PERF_END(PERFORMANCE_COUNTER_0_BASE, 1);

}

//////////////////////////////////////////////////////////////////////////////////////
volatile uint8_t flagwait = 1; // Signals when we're ready to start printing. active low.
/**message interrupt, receives some pointer and assigns it according to the message type.**/
static void rx_cb (void* message){ 
  if(message != NULL) {
	  uint32_t msg = ((uint32_t*)message)[1];
	  uint32_t msgtype = ((uint32_t*)message)[0];
	  printf("got message: %c\n",msgtype);
	  switch(msgtype){
	  case 'W':
		  world_map = (uint8_t*) msg;
		  break;
	  case 'S':
		  game_status = (uint8_t*)msg;
		  printf("got game status: %c\n",*game_status);
		  break;
	  case 'P':
		  player_score = (uint8_t*)msg;
		  break;
	  case 'C':
		  computer_score = (uint8_t*)msg;
		  break;
	  case 'G':
	    printf("GO received!");
	      flagwait =0;
	      break;
	  default:
		  break;
	  }
  } else {
      printf("incomplete receive\n");
  }

}

static void init() {
  printf("initializing... cpu0\n");
	mutti = altera_avalon_mutex_open(MUTEX_0_NAME);
	IOWR(MAILBOX_SIMPLE_0_BASE, 3, 0x1);
	ledmatrix = new LedControl(DIN, CLK, CS, 1);
  	ledmatrix->shutdown(0, false); // normal operations
	ledmatrix->setIntensity(0, 3); // adjust the brightness (max. 15)
	ledmatrix->clearDisplay(0);

	altera_avalon_mailbox_dev* recv_dev = altera_avalon_mailbox_open(MAILBOX_SIMPLE_0_NAME, NULL, rx_cb);

	while(flagwait)
	{

//		alt_u32 val = altera_avalon_mailbox_status(recv_dev); //IORD(MAILBOX_SIMPLE_0_BASE,0x2);
//		printf("waiting for message, val: %u    %u\n",val,flagwait);
//		usleep(100000);
	  //wait until GO message is received. 
	}
	
  PERF_START_MEASURING(PERFORMANCE_COUNTER_0_BASE);
	alt_ic_isr_register(TIMER_0_IRQ_INTERRUPT_CONTROLLER_ID, TIMER_0_IRQ, refresh_isr, NULL, NULL);
	
	/**different frequencies depending if we're on the matrix or in the terminal**/
	#ifndef nomatrix
	IOWR_ALTERA_AVALON_TIMER_PERIODL(TIMER_0_BASE, 0x4240); // 50Hz -> 20ms: 1M clock ticks
	IOWR_ALTERA_AVALON_TIMER_PERIODH(TIMER_0_BASE, 0x000F);
	IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, 0b0111); // STOP:0, START:1, CONT:1, ITO:1
	#else
	IOWR_ALTERA_AVALON_TIMER_PERIODL(TIMER_0_BASE, 0x4240); // 50Hz -> 20ms: 1M clock ticks
	IOWR_ALTERA_AVALON_TIMER_PERIODH(TIMER_0_BASE, 0x020F);
	IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, 0b0111); // STOP:0, START:1, CONT:1, ITO:1
	#endif
	printf("ledmatrix init done\n\n");
}

int main() {


	 init();
  
  printf("busy wait... \n");

#ifndef nomatrix
	printf("LED MATRIX\n");

	/* Event loop never exits. */
    while(1) {
    	printf("Still looping here\n");
      	usleep(1000000);
	if(measuring)
	  {
	    PERF_STOP_MEASURING(PERFORMANCE_COUNTER_0_BASE);
	    perf_print_formatted_report(PERFORMANCE_COUNTER_0_BASE,alt_get_cpu_freq(),1,"try1");
	  }

	measuring = 0;
    }

    #else
    volatile int i=0;
	while(1) {

	  printf("hello,world. i: %u\n",i);
	  //IOWR_ALTERA_AVALON_TIMER_CONTROL(TIMER_0_BASE, 0b0111); // STOP:0, START:1, CONT:1, ITO:1
//		if(i++ % 10 == 0) {
//			i=0;
//			altera_avalon_mutex_lock(mutti,3);
//			int val = IORD_8DIRECT(world_map,0);
//			if (val == 0)
//				printf("playerspace is 0!\n");
//			for (int i = 0; i<8;i++){
//			  printf("%u ",i);
//			  printf(BYTE_TO_BINARY_PATTERN,(uint8_t)BYTE_TO_BINARY(IORD_8DIRECT(world_map,i)));
//			  //printf("%x",IORD_8DIRECT(world_map,i));
//			  printf("\n");
//			}
//			char status =IORD_8DIRECT(game_status,0);
//			 printf("status : %c \n",status);
//			printf("\n");
//			altera_avalon_mutex_unlock(mutti);
			usleep(1000009);i++;
//		}
	}
#endif

    return 0;
}

