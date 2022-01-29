#include <inttypes.h>
#include <stdlib.h>
#include <io.h>
#include <system.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/alt_irq.h>
#include <altera_avalon_pio_regs.h>
#include <altera_avalon_mutex.h>
#include <altera_avalon_performance_counter.h>
#include <altera_avalon_mutex_regs.h>
#include <altera_avalon_timer.h>
#include <altera_avalon_timer_regs.h>
#include <altera_avalon_mailbox_simple.h>
#include <altera_avalon_mailbox_simple_regs.h>
#include <includes.h>
#include <sys/alt_cache.h>

/* Memory access control */
alt_mutex_dev* mutti; // hardware mutex used for shared memory access
const uint16_t difficulties [8] = {750, 650,600,500,375,250,150,100};
const uint16_t bull_speeds[8] =   {210,190,170,150,130,110,100,90};
uint16_t * current_bullspeed = &bull_speeds[0];
uint16_t * current_difficulty = &difficulties[0];
#define BYTE_TO_BINARY_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0')
//////////////////////////////////////////////////////////////////////////////////////

/* Game related variables & flags */
static uint8_t playerfield[8]; // game field but only p1 parts
static uint8_t computerfield[8]; // game field but only p2 parts
static uint8_t recentshot_player;
static uint8_t recentshot_computer;
static uint8_t player_ready;

static uint8_t world_map_val[8];
static uint8_t* world_map = world_map_val;// = (uint8_t*) malloc(64);

static uint8_t game_status_val;
static uint8_t* game_status = &game_status_val;// = (uint8_t*) malloc(64);

static uint8_t player_score_val; // 	ONCHIP_MEMORY2_0_BASE+1
static uint8_t* player_score =&player_score_val;  // 	ONCHIP_MEMORY2_0_BASE+1

static uint8_t computer_score_val;
static uint8_t* computer_score = &computer_score_val;//	ONCHIP_MEMORY2_0_BASE+2
//////////////////////////////////////////////////////////////////////////////////////
int measuring = 1;
/* assigns one byte to an address and clears that byte in cache **/
static inline void assign_cacheless(uint8_t* in,uint8_t val) 
{
  *in = val;
  alt_dcache_flush((void*)in,1);
}
static void reset_score(void) {
  altera_avalon_mutex_lock(mutti,1);
  
	if(*player_score == 0xFF) {
	  assign_cacheless(game_status,'P');
	} else {
	  assign_cacheless(game_status,'C');
	}
	current_difficulty = &difficulties[0];
	current_bullspeed= &bull_speeds[0];
	assign_cacheless(player_score,0);
	assign_cacheless(computer_score,0);
	altera_avalon_mutex_unlock(mutti);
	if (measuring){
	  measuring = 0;
	  PERF_STOP_MEASURING(PERFORMANCE_COUNTER_1_BASE);
	  perf_print_formatted_report(PERFORMANCE_COUNTER_1_BASE,alt_get_cpu_freq(),3,"playermove","computermove","movebullets");
	}
}

/*Resets the game field to default state. Does not overwrite scores or gamestatus*/
static void reset_game(void) {
	altera_avalon_mutex_lock(mutti, 2);
	
	for(int i = 0; i < 8; i++) {
	  assign_cacheless(&world_map[i],0);
	  playerfield[i] = 0;
	  computerfield[i] = 0;
	}
	playerfield[0] = 0b00111000;
	computerfield[7] = 0b00111000;
	assign_cacheless(&world_map[0],playerfield[0]);
	assign_cacheless(&world_map[7],computerfield[7]);

	altera_avalon_mutex_unlock(mutti);
	if(*player_score == 0xFF || *computer_score == 0xFF) {
		reset_score();
	}
	recentshot_player = 0;
	recentshot_computer = 0;
	player_ready = 0;
}

/*checks if the computer or the player has won.*/
static void check_win(char playerwin, char computerwin) {
	  altera_avalon_mutex_lock(mutti,3);

	if(playerwin && computerwin) {
	  assign_cacheless(game_status,'d');
		reset_game();
	} 
	else if(playerwin) {
	  assign_cacheless(game_status,'p');
	  assign_cacheless(player_score,((*player_score >> 1) | 0x80));
	  current_difficulty++;
	  current_bullspeed++;
	  reset_game();
	} 
	else if(computerwin) {
		assign_cacheless(game_status,'c');
		assign_cacheless(computer_score,((*computer_score << 1) | 0x01));
		reset_game();
	} 
	else {
	  if(player_ready)
	    assign_cacheless(game_status,'W');
	}
	altera_avalon_mutex_unlock(mutti);
}

//////////////////////////////////////////////////////////////////////////////////////

/* Definition of Task Stacks */
#define TASK_STACKSIZE	2048
OS_STK  task2_stk[TASK_STACKSIZE];
OS_STK  task3_stk[TASK_STACKSIZE];

/* Definition of Task Priorities */
#define TASK2_PRIORITY	2
#define TASK3_PRIORITY  3


/* Update game map with bullets' displacement at time steps of varying difficulty */
static void movebullets(void* pdata) 
{
  void remove_collisions() // helperfunction that removes the overlapping bullets
	{
	    uint8_t tmp2 = playerfield[7];

	    uint64_t overlap = *((uint64_t*)playerfield) & (*((uint64_t*)computerfield));
	    *((uint64_t*)playerfield) &= ~overlap;
	    playerfield[7] = tmp2;

	    tmp2 = computerfield[0];
	    *((uint64_t*)computerfield) &= ~overlap;
	    computerfield[0] = tmp2;
	}
	while(1) {

		if(player_ready) {
		  if(measuring)
		  PERF_BEGIN(PERFORMANCE_COUNTER_1_BASE, 3);
			uint8_t tmp[7];
			remove_collisions();

			/** move players bullets one step down. **/
			memcpy(tmp,playerfield+1,7);
			memcpy(playerfield+2,tmp,6);

			/*** handle recent shots . **/
			playerfield[1] = recentshot_player;
			recentshot_player = 0;

			/** Check if player has won **/
			char playerwin = computerfield[7] & playerfield[7];
			remove_collisions();

			/**move computers bulltes one step up **/
			memcpy(tmp,computerfield,7);
			memcpy(computerfield,tmp+1,6);

			/** handle recent shots**/
			computerfield[6] = recentshot_computer;
			recentshot_computer = 0;

			/** Check if computer has won **/
			char computerwin = computerfield[0] & playerfield[0];
			check_win(playerwin, computerwin);
			
			altera_avalon_mutex_lock(mutti, 4);
			/*write the world to memory for cpu0 to access*/
			for (int i = 0; i < 8; i++) {
			  assign_cacheless(&world_map[i],playerfield[i] | computerfield[i]);
			}
		
			altera_avalon_mutex_unlock(mutti);
			
		  if(measuring)
		    PERF_END(PERFORMANCE_COUNTER_1_BASE, 3);
		  OSTimeDlyHMSM(0,0,0,*current_bullspeed);
		}
	}
}

/* Update game map with random computer move */
static void computermove(void* pdata) {
	while(1) {

		  if(measuring)
		    PERF_BEGIN(PERFORMANCE_COUNTER_1_BASE, 2);
		int plant = rand();
		if(plant % 2 == 0) {
			// Move right (prevent out of map move)
			if(computerfield[7] != 0b00000111) {
				computerfield[7] = computerfield[7] >> 1;
			}
		} else {
			// Move left (prevent out of map move)
			if(computerfield[7] != 0b11100000) {
				computerfield[7] = computerfield[7] << 1;
			}
		}
		if(player_ready ){
		  plant = rand();
		  if(plant % 2 == 0) {
			// Shoot bullet from current position
			recentshot_computer = computerfield[7] & (computerfield[7] << 1) & (computerfield[7] >> 1);
		  }
		  check_win(playerfield[7] & computerfield[7],0);
		}
		// write changes to the map
		altera_avalon_mutex_lock(mutti, 5);
		assign_cacheless(&world_map[7],computerfield[7] | playerfield[7]);
		altera_avalon_mutex_unlock(mutti);
		
		// pause task for delay adapted to computer movement speed
		  if(measuring)
		    PERF_END(PERFORMANCE_COUNTER_1_BASE, 2);
		OSTimeDlyHMSM(0, 0, 0, *current_difficulty);
	}
}

//////////////////////////////////////////////////////////////////////////////////////

/* Update game map with player's chosen move. This is the buttons' ISR */
static void playermove(void* context) {

  if(measuring)
    PERF_BEGIN(PERFORMANCE_COUNTER_1_BASE, 1);
    switch(IORD_ALTERA_AVALON_PIO_EDGE_CAP(PIO_0_BASE)) {
      case 0b001: // Move right (prevent out of map move)
        if(playerfield[0] != 0b00000111) {
	  playerfield[0] = playerfield[0] >> 1;
	  player_ready = 1;
        }
        break;
      case 0b010: // shoot
	if(player_ready)
	  recentshot_player = playerfield[0] & (playerfield[0] << 1) & (playerfield[0] >> 1);
	    break;
      case 0b100: //Move left (prevent out of map move)
	    if(playerfield[0] != 0b11100000) {
		    playerfield[0] = playerfield[0] << 1;
		    player_ready = 1;
	  	}
	    break;
      default: // invalid call
    	break;
  	}
    // write changes to the map
    altera_avalon_mutex_lock(mutti, 6);
	check_win(0, playerfield[0] & computerfield[0]);
	assign_cacheless(&world_map[0],playerfield[0] | computerfield[0]);
	altera_avalon_mutex_unlock(mutti);
	
	// acknowledge interrupt
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(PIO_0_BASE, 0x0);
	if(measuring)
	  PERF_END(PERFORMANCE_COUNTER_1_BASE, 1);
}
/////////////////////////////////////////////////////////////////////////////////////
static void init(void) {
  printf("initializing..cpu1\n");
    mutti = altera_avalon_mutex_open(MUTEX_0_NAME);
    alt_ic_isr_register(PIO_0_IRQ_INTERRUPT_CONTROLLER_ID, PIO_0_IRQ, playermove, NULL, NULL);
    IOWR_ALTERA_AVALON_PIO_EDGE_CAP(PIO_0_BASE, 0x0);
    IOWR_ALTERA_AVALON_PIO_IRQ_MASK(PIO_0_BASE, 0xF);

    reset_game();
    assign_cacheless(game_status,'W');
    assign_cacheless(player_score,0);
    assign_cacheless(computer_score,0);

    IOWR(MAILBOX_SIMPLE_0_BASE,0x1,world_map); //send pointer to World map to CPU0
    IOWR(MAILBOX_SIMPLE_0_BASE,0x0,'W'); // send the message with a message type descriptor.


    IOWR(MAILBOX_SIMPLE_0_BASE,0x1,game_status); //send the game status pointer to CPU0
    IOWR(MAILBOX_SIMPLE_0_BASE,0x0,'S'); /// send the message with a message type descriptor.
    

    IOWR(MAILBOX_SIMPLE_0_BASE,0x1,player_score); //send the player score pointer to CPU0
    IOWR(MAILBOX_SIMPLE_0_BASE,0x0,'P'); /// send the message with a message type descriptor.


    IOWR(MAILBOX_SIMPLE_0_BASE,0x1,computer_score); //send the computer score pointer to CPU0
    IOWR(MAILBOX_SIMPLE_0_BASE,0x0,'C'); /// send the message with a message type descriptor.
    

    IOWR(MAILBOX_SIMPLE_0_BASE,0x1,0x0); //arbitrary value 
    IOWR(MAILBOX_SIMPLE_0_BASE,0x0,'G'); ///signals CPU0 to "GO" and start printing 

    PERF_START_MEASURING(PERFORMANCE_COUNTER_1_BASE);
}
int main() {

	init();
	printf("Game logic init done! \n");
	OSTaskCreateExt(computermove,
				    NULL,
				    (void *)&task2_stk[TASK_STACKSIZE-1],
				    TASK2_PRIORITY,
				    TASK2_PRIORITY,
				    task2_stk,
				    TASK_STACKSIZE,
				    NULL,
				    0);
	OSTaskCreateExt(movebullets,
				    NULL,
				    (void *)&task3_stk[TASK_STACKSIZE-1],
				    TASK3_PRIORITY,
				    TASK3_PRIORITY,
				    task3_stk,
				    TASK_STACKSIZE,
				    NULL,
				    0);
	
	OSStart();
  return 0;
}
