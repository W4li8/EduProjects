/*    MT_BA1 Programmation I          */
/*    Projet d'Automne : Me Too ?     */
/*        			   : Rendu F      */


/*/
 * \file		286557.c
 * \version		Rendu Final
 * \author		Nom: Slezák Filip et SCIPER: 286557
 * \brief		Programme : Me Too? , pour le projet du cours CS-111(c)
 /*/



#include <math.h>
#include <time.h>
#include <string.h>
#include <stdbool.h>

#include <stdlib.h>
#include <stdio.h>



/* ################################################################################# */
/* Partie Obligatoire 																 */


// erreur, nbSim incompatible
static void erreur_nbSim(int nbSim) {
	printf("nbSim (=%d) ne valide pas nbSim > 0 !\n", nbSim);
}


// erreur, n incompatible
static void erreur_taille_monde(int n) {
	printf("n (=%d) ne valide pas n > 1 !\n", n);
}


// erreur, nbP incompatible
static void erreur_nbP(int nbP, int n) {
	printf("nbP (=%d) ne valide pas nbP > 1 ET nbP <= %d !\n", nbP, n*n);
}


// erreur, une coordonnée donnée est incompatible
static void erreur_indice_ligne_colonne(int indice, int indiceperson) {
	printf("indice incorrect %d de ligne ou colonne de la person d'indice %d !\n",
		   indice, indiceperson);
}


// erreur, il y a superposition de 2 personnes
static void erreur_superposition(int indiceP_A, int indiceP_B) {
	if (indiceP_B > indiceP_A) {
		int temp = indiceP_A;
		indiceP_A = indiceP_B;
		indiceP_B = temp;
	}
	printf("les personnes d'indices %d et %d se superposent !\n",
		   indiceP_A, indiceP_B);
}


// definition de verbose, sociabilité de l'utilisateur
static bool verbose;



#define MAX_CYCLES 200



/* ################################################################################# */
/* Partie Libre 																	 */
/* Rendu Intermédiaire																 */

/* Structures et valeurs sentinelles 												 */


//Status possibles des personnes
enum statuses {S_HEALTHY, S_INCUBATION, S_INFECTED, S_IMMUNE};

//Informations sur chaque personne
struct infos_person {
	int pos_y;
	int pos_x;
	int goal_y;
	int goal_x;
	enum statuses status;
};


//Directions envisageables de chaque personne
enum directions {D_NORTH, D_NORTH_WEST, D_WEST, D_SOUTH_WEST,
	D_SOUTH, D_SOUTH_EAST, D_EAST, D_NORTH_EAST};



/* ################################################################################# */
/* Initialisation       															 */


//nbSim
static void check_nbSim (int nbSim) {
	int min_nbSim = 1;
	if (nbSim < min_nbSim) {
		erreur_nbSim (nbSim);
		exit(EXIT_FAILURE);
	}
}//OK


//n
static void check_n (int n) {
	int min_world_size = 2;
	if (n < min_world_size) {
		erreur_taille_monde (n);
		exit(EXIT_FAILURE);
	}
}//OK


//nbP
static void check_nbP (int nbP, int n) {
	int min_nbP, max_nbP;
	
	min_nbP = 2;
	max_nbP = n*n;
	
	if (nbP < min_nbP || nbP > max_nbP) {
		erreur_nbP (nbP, n);
		exit(EXIT_FAILURE);
	}
}//OK


//Coordonnées
static void check_coordinates (int person, int value, int min, int max, char *msg) {
	if (value < min || value > max) {
		if (verbose)
			printf("%s de la person d'indice %d est %d et doit etre entre\
				   %d et %d.\n", msg, person, value, min, max );
		//erreur_indice_ligne_colonne
		erreur_indice_ligne_colonne (value, person);
		exit(EXIT_FAILURE);
	}
}//OK


static void verify_coordinates (int i, int n, int pos_y, int pos_x,
								int goal_y, int goal_x) {
	int max = n - 1, min = 0;
	//Séparation des cas, pas nécessaire mais pratique
	check_coordinates (i, pos_y, min, max, "# La coordonnee de position Y");
	check_coordinates (i, pos_x, min, max, "# La coordonnee de position X");
	check_coordinates (i, goal_y, min, max, "# La coordonnee de but Y");
	check_coordinates (i, goal_x, min, max, "# La coordonnee de but X");
}//OK


static void check_superposition (int i, struct infos_person people[i]) {
	for (int j = 0; j < i; j++) {
		if (people[i].pos_y == people[j].pos_y
			&& people[i].pos_x == people[j].pos_x) {
			erreur_superposition(j, i);
			exit(EXIT_FAILURE);
		}
	}
}//OK


//Initialisation des paramètres verbose, affichage_monde, nbSim, n, nbP
static void init_parameters (bool *show_world, int *nbSim,int *n, int *nbP) {
	int talk_to_me, show_me;
	//verbose
	scanf("%d", &talk_to_me);
	verbose = talk_to_me;
	
	//Affichage_monde
	if (verbose)
		printf("# Salutations humain ! \nVeux-tu pouvoir admirer ton oeuvre?\n");
	scanf("%d", &show_me);
	*show_world = show_me;
	
	//nbSim
	if (verbose)
		printf("# Combien de fois voudrais-tu contaminer la population?\n");
	scanf("%d", nbSim);
	check_nbSim(*nbSim);
	
	//n
	if (verbose)
		printf("# Quelle est la taille du monde que tu veux contaminer?\n");
	scanf("%d", n);
	check_n (*n);
	
	//nbP
	if (verbose)
		printf("# Combien de personnes habitent ce monde?\n");
	scanf("%d", nbP);
	check_nbP (*nbP, *n);
}//OK


//Initialisation coordonnées
static void init_coordinates (int n, int nbP, struct infos_person *people) {
	int first_person_index = 0;
	
	if (verbose)
		printf("# Maintenant, entre un par un les emplacements de ces personnes\
			   ainsi que leur but?\n");
	
	for (int i = 0; i < nbP; i++) {
		scanf("%d %d %d %d", &(people[i].pos_y), &(people[i].pos_x),
			  &(people[i].goal_y), &(people[i].goal_x));
		//Etat initial des personnes
		if (i == first_person_index)
			people[i].status = S_INFECTED;
		
		else
			people[i].status = S_HEALTHY;
		//erreur_coordonnees
		verify_coordinates (i, n, people[i].pos_y, people[i].pos_x,
							people[i].goal_y, people[i].goal_x);
		//erreur_superposition
		check_superposition (i, people);
	}
}//OK



/* ################################################################################# */
/* Simulation    																	 */
/* Rendu Final    																	 */

/* Sauvegarde des données															 */


//Réinitialise les données avec lesquelles on travaille
static void reset_data (int nbP, struct infos_person *people,
						struct infos_person *original_people) {
	for (int i = 0; i < nbP; i++) {
		people[i] = original_people[i];
	}
}//OK


//Affiche le monde
static void display_world (int n, int nbP, struct infos_person *people) {
	char world[n][n];
	//Vide le monde
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			world[i][j] = '^';
		}
	}
	//Place les personnes dans le monde
	for (int k = 0; k < nbP; k++) {
		switch (people[k].status) {
			case S_IMMUNE:
				world[people[k].pos_y][people[k].pos_x] = 'V';
				break;
			case S_HEALTHY:
				world[people[k].pos_y][people[k].pos_x] = 'N';
				break;
			case S_INFECTED:
				world[people[k].pos_y][people[k].pos_x] = 'C';
				break;
			default:
				break;
		}
		//Place les buts dans le monde (priorité aux personnes)
		if (world[people[k].goal_y][people[k].goal_x] == '^')
			world[people[k].goal_y][people[k].goal_x] = 'b';
	}
	//Affichage du monde
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < n; j++) {
			printf("%c ", world[i][j]);
		}
		printf("\n");
	}
	printf("\n");
}//OK


//Ajuste une valeur qui dépasse du monde - pour gérer le rebouclement
static int world_wrap (int value, int n) {
	if (value == n)
		return 0;
	
	if (value == -1)
		return n - 1;
	
	return value;
}//OK, aurait pu être plus efficace


//Définit un nouveau but
static void define_new_goal (int n, struct infos_person *people, int i) {
	int new_goal_y, new_goal_x;
	//Pour entrer dans la boucle une première fois
	new_goal_y = people[i].pos_y;
	new_goal_x = people[i].pos_x;
	//Tant que le but n'est pas différent de la position actuelle
	while (new_goal_y == people[i].pos_y && new_goal_x == people[i].pos_x) {
		//Pour éviter le cas où on obtient n
		new_goal_y = n;
		while (new_goal_y == n)
			new_goal_y = ((double) rand()/RAND_MAX)*n;
		
		//Pour éviter le cas où on obtient n
		new_goal_x = n;
		while (new_goal_x == n)
			new_goal_x = ((double) rand()/RAND_MAX)*n;
	}
	people[i].goal_y = new_goal_y;
	people[i].goal_x = new_goal_x;
	//Pratique pour savoir ce qui se passe
	if (verbose)
		printf("# La personne d'indice %d en %d %d a atteint son but ou elle n'est pas\
			   en mesure de bouger, son nouveau but est %d %d\n",
			   i, people[i].pos_y, people[i].pos_x, new_goal_y, new_goal_x);
}//OK


//Calcule la distance la plus courte en tenant compte du rebouclement du monde
//Change la direction de la personne si la nouvelle distance calculée est plus courte
static void select_direction (int pos_y, int pos_x, int goal_y, int goal_x,
							  int n, int *current_minimal_distance,
							  int *current_direction, int possible_direction) {
	int yy, xx, distance;
	//Distance la plus courte selon y
	yy = abs(pos_y - goal_y);
	if (yy > n/2)
		yy = n - yy;
	//Distance la plus courte selon x
	xx = abs(pos_x - goal_x);
	if (xx > n/2)
		xx = n - xx;
	//Sert seulement pour comparaison, pas besoin de prendre la racine carrée
	distance = yy*yy + xx*xx;
	if (distance < *current_minimal_distance) {
		*current_minimal_distance = distance;
		*current_direction = possible_direction;
	}
}//OK


//Choisit la direction la plus efficace
//Commence par le nord et continue dans le sens antihoraire
//Pour un total de 8 directions
static void optimal_direction (int n,  int pos_y, int pos_x, int goal_y, int goal_x,
							   int *direction, int *initial_direction) {
	//Résultat de la fonction select_direction
	int optimal_direction;
	//Initialisation, valeur centinelle inatteignable
	int min_dist = n*n;
	//Initialisation de la direction comme étant le nord
	select_direction (world_wrap (pos_y - 1, n), pos_x,
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_NORTH);
	
	//La direction nord-ouest est-elle plus efficace?
	select_direction (world_wrap (pos_y - 1, n), world_wrap (pos_x - 1, n),
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_NORTH_WEST);
	
	//La direction ouest est-elle plus efficace?
	select_direction (pos_y, world_wrap (pos_x - 1, n),
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_WEST);
	
	//La direction sud-ouest est-elle plus efficace?
	select_direction (world_wrap (pos_y + 1, n), world_wrap (pos_x - 1, n),
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_SOUTH_WEST);
	
	//La direction sud est-elle plus efficace?
	select_direction (world_wrap (pos_y + 1, n), pos_x,
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_SOUTH);
	
	//La direction sud-est est-elle plus efficace?
	select_direction (world_wrap (pos_y + 1, n), world_wrap (pos_x + 1, n),
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_SOUTH_EAST);
	
	//La direction est est-elle plus efficace?
	select_direction (pos_y, world_wrap (pos_x + 1, n),
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_EAST);
	
	//La direction nord-est est-elle plus efficace?
	select_direction (world_wrap (pos_y - 1, n), world_wrap (pos_x + 1, n),
					  goal_y, goal_x, n, &min_dist, &optimal_direction, D_NORTH_EAST);
	
	*direction = optimal_direction;
	*initial_direction = optimal_direction;
}//OK


//Vérifie si le mouvement de la personne est possible
static bool check_move (int nbP, int new_y, int new_x, struct infos_person *people) {
	for (int i = 0; i < nbP; i++) {
		if (people[i].pos_y == new_y && people[i].pos_x == new_x)
			return false;
	}
	return true;
}//OK


//Déplace la personne si possible, sinon en informe la fonction movement
static void move (int nbP, int new_y, int new_x, struct infos_person *people, int i,
				  bool *completed) {
	bool blocked = true;
	
	if (check_move (nbP, new_y, new_x, people) == true) {
		blocked = false;
		
		people[i].pos_y = new_y;
		people[i].pos_x = new_x;
	}
	*completed = !blocked;
}//OK


//Bouge la personne vers son but
//Si sa direction se trouve obstruée elle est dirigée ailleurs
//Si elle est entourée (bloquée à 100%) on lui définit un nouveau but
static void movement (int n, int nbP, struct infos_person *people, int i) {
	//Donné par la fonction move, initialisé à false par défaut
	bool completed = false;
	//Donné par la fonction optimal_direction qui choisit de la direction à prendre
	int direction, initial_direction;
	optimal_direction (n, people[i].pos_y, people[i].pos_x, people[i].goal_y,
					   people[i].goal_x, &direction, &initial_direction);
	
	//Si il peut bouger dans sa direction optimale, le faire, sinon, essayer les autres
	do {
		switch (direction) {
			case D_NORTH:
				move (nbP, world_wrap (people[i].pos_y - 1, n),
					  people[i].pos_x, people, i, &completed);
				direction = D_NORTH_WEST;
				break;
			case D_NORTH_WEST:
				move (nbP, world_wrap (people[i].pos_y - 1, n),
					  world_wrap (people[i].pos_x - 1, n), people, i, &completed);
				direction = D_WEST;
				break;
			case D_WEST:
				move (nbP, people[i].pos_y,
					  world_wrap (people[i].pos_x - 1, n), people, i, &completed);
				direction = D_SOUTH_WEST;
				break;
			case D_SOUTH_WEST:
				move (nbP, world_wrap (people[i].pos_y + 1, n),
					  world_wrap (people[i].pos_x - 1, n), people, i, &completed);
				direction = D_SOUTH;
				break;
			case D_SOUTH:
				move (nbP, world_wrap (people[i].pos_y + 1, n),
					  people[i].pos_x, people, i, &completed);
				direction = D_SOUTH_EAST;
				break;
			case D_SOUTH_EAST:
				move (nbP, world_wrap (people[i].pos_y + 1, n),
					  world_wrap (people[i].pos_x + 1, n), people, i, &completed);
				direction = D_EAST;
				break;
			case D_EAST:
				move (nbP, people[i].pos_y,
					  world_wrap (people[i].pos_x + 1, n), people, i, &completed);
				direction = D_NORTH_EAST;
				break;
			case D_NORTH_EAST:
				move (nbP, world_wrap (people[i].pos_y - 1, n),
					  world_wrap (people[i].pos_x + 1, n), people, i, &completed);
				direction = D_NORTH;
				break;
		}
	} while (completed == false && initial_direction != direction);
	
	//Si la personne est encerclée, definition d'un nouveau but
	if (completed == false) //Dans ce cas initial_direction == direction
		define_new_goal(n, people, i);
}//OK


//Infecte la personne concernée, si nécessaire
static void infection (int n, int nbP, int pos_y_check, int pos_x_check,
					   struct infos_person *people, int i) {
	for (int j = 0; j < nbP; j++) {
		if (people[j].pos_y == pos_y_check && people[j].pos_x == pos_x_check) {
			if (people[i].status == S_HEALTHY && people[j].status == S_INFECTED)
				people[i].status = S_INCUBATION;
			
			if (people[j].status == S_HEALTHY && people[i].status == S_INFECTED)
				people[j].status = S_INCUBATION;
		}
	}
}//OK


//Vérifie la contamination aux 8 cases voisines
static void check_infection (int n, int nbP, struct infos_person *people, int i) {
	//Vérifier l'infection potentielle au nord
	infection (n, nbP, world_wrap (people[i].pos_y - 1, n),
			   people[i].pos_x, people, i);
	
	//Vérifier l'infection potentielle au nord-ouest
	infection (n, nbP, world_wrap (people[i].pos_y - 1, n),
			   world_wrap (people[i].pos_x - 1, n), people, i);
	
	//Vérifier l'infection potentielle au ouest
	infection (n, nbP, people[i].pos_y,
			   world_wrap (people[i].pos_x - 1, n), people, i);
	
	//Vérifier l'infection potentielle au sud-ouest
	infection (n, nbP, world_wrap (people[i].pos_y + 1, n),
			   world_wrap (people[i].pos_x - 1, n), people, i);
	
	//Vérifier l'infection potentielle au sud
	infection (n, nbP, world_wrap (people[i].pos_y + 1, n),
			   people[i].pos_x, people, i);
	
	//Vérifier l'infection potentielle au sud-est
	infection (n, nbP, world_wrap (people[i].pos_y + 1, n),
			   world_wrap (people[i].pos_x + 1, n), people, i);
	
	//Vérifier l'infection potentielle au est
	infection (n, nbP, people[i].pos_y,
			   world_wrap (people[i].pos_x + 1, n), people, i);
	
	//Vérifier l'infection potentielle au nord-est
	infection (n, nbP, world_wrap (people[i].pos_y - 1, n),
			   world_wrap (people[i].pos_x + 1, n), people, i);
}//OK


//Change le statut des personnes en état d'incubation en contaminé
static void ending_infection (int nbP, struct infos_person *people) {
	for (int i = 0; i < nbP; i++) {
		if (people[i].status == S_INCUBATION)
			people[i].status = S_INFECTED;
	}
}//OK


//Vérifie si tout le monde est contaminé
static bool all_infected (int nbP, struct infos_person *people) {
	for (int i = 0; i < nbP; i++) {
		if (people[i].status == S_HEALTHY)
			return false;
	}
	return true;
}//OK


//Se charge de l'infection initiale
static bool initial_infection (int n, int nbP, struct infos_person *people) {
	int first_person_index = 0;
	
	check_infection (n, nbP, people, first_person_index);
	
	ending_infection(nbP, people);
	
	return all_infected (nbP, people);
}//OK


//Fonction de vaccination
static void immunisation (int nbP_vaccinated, struct infos_person *people) {
	for (int i = 1; i <= nbP_vaccinated; i++) {
		people[i].status = S_IMMUNE;
	}
}//OK


//Trie le tableau des nbSim résultats obtenus et renvoie la valeur médiane
static float find_median (int nbSim, int *results) {
	int i = 0;
	while (i < nbSim - 1) {
		if (results[i] <= results[i + 1])
			++i;
		
		else {
			int temp = results[i];
			results[i] = results[i + 1];
			results[i + 1] = temp;
			
			i = 0;
		}
	}
	//Si nbSim pair, moyenne des valeurs médianes
	if (nbSim % 2 == 0)
		return (float) (results[nbSim/2 - 1] + results[nbSim/2])/2;
	//Si nbSim impair, valeur médiane
	return results[nbSim/2];
}//OK


//Affiche les résultats
static void sim_result (int n, int nbP, int nbP_vaccinated, int *results, int nbSim) {
	float density, vaccination, median_cycles;
	
	density = (float) nbP/(n*n);
	vaccination = (float) nbP_vaccinated/nbP;
	median_cycles = find_median (nbSim, results);
	
	printf("%f %.4f %.2f\n", density, vaccination, median_cycles);
}//OK


//Simulation de Me Too?
static void simulation (bool show_world, int nbSim, int n, int nbP,
						struct infos_person *people, struct infos_person *original_people) {
	int results[nbSim];
	int nbP_vaccinated, cycle;
	bool stop;
	
	while (nbP > 1) {
		nbP_vaccinated = 0;
		while (nbP_vaccinated < nbP - 1) {
			for (int j = 0; j < nbSim; j++) {
				if (verbose)
					printf("# Caractéristiques: nbP %d Vaccinés %d nbSim %d\n",
						   nbP, nbP_vaccinated, j + 1);
				//Copie des données initiales pour la simulation
				reset_data (nbP, people, original_people);
				//Vaccine les personnes concernées
				immunisation (nbP_vaccinated, people);
				//Cela vaut-il la peine d'arrêter le programme ?
				stop = initial_infection (n, nbP, people);
				
				cycle = 0;
				while (stop == false && cycle < MAX_CYCLES) {
					if (show_world)
						display_world (n, nbP, people);
					
					for (int i = 0; i < nbP; i++) {
						//Si la personne est à son but, définir un nouveau but
						if (people[i].pos_y == people[i].goal_y
							&& people[i].pos_x == people[i].goal_x)
							define_new_goal (n, people, i);
						
						//Déplacer la personne
						movement (n, nbP, people, i);
						
						//Vérifier les contaminations (IO)
						check_infection (n, nbP, people, i);
					}
					//Les incubés deviennent contaminés
					ending_infection (nbP, people);
					
					stop = all_infected (nbP, people);
					++cycle;
				}
				if (show_world)
					display_world (n, nbP, people);
				
				results[j] = cycle;
			}
			sim_result (n, nbP, nbP_vaccinated, results, nbSim);
			
			++nbP_vaccinated;
		}
		//Pour Gnuplot
		printf("\n");
		
		--nbP;
	}
}//OK


//La pièce maitresse
int main () {
	bool show_world;
	int nbSim, n, nbP;
	//	srand (0);
	srand ((int) time(NULL));
	
	//Initialisation
	init_parameters (&show_world, &nbSim, &n, &nbP);
	
	struct infos_person original_people[nbP];
	struct infos_person people[nbP];
	
	init_coordinates (n, nbP, original_people);
	
	//Simulation
	simulation (show_world, nbSim, n, nbP, people, original_people);
	
	return EXIT_SUCCESS;
}
