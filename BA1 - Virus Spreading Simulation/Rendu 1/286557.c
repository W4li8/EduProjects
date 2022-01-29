/*    MT-BA1 Programmation I          */
/*    Projet d'Automne : Me Too ?     */
/*        			   : Rendu I      */

/*/
 * \file		286557.c
 * \version		Premier Rendu
 * \author		Nom: Slezák Filip et SCIPER: 286557
 * \brief		Programme pour le projet du cours CS-111(c)
 /*/

#include <math.h>
#include <time.h>
#include <string.h>
#include <stdbool.h>

#include <stdlib.h>
#include <stdio.h>
				// PARTIE OBLIGATOIRE //
/* erreur, nbSim incompatible */
static void erreur_nbSim(int nbSim) {
	printf("nbSim (=%d) ne valide pas nbSim > 0 !\n", nbSim);
}
/* erreur, n incompatible */
static void erreur_taille_monde(int n) {
	printf("n (=%d) ne valide pas n > 1 !\n", n);
}
/* erreur, nbP incompatible */
static void erreur_nbP(int nbP, int n) {
	printf("nbP (=%d) ne valide pas nbP > 1 ET nbP <= %d !\n", nbP, n*n);
}
/* erreur, une coordonnée donnée est incompatible */
static void erreur_indice_ligne_colonne(int indice, int indicePersonne) {
	printf("indice incorrect %d de ligne ou colonne de la personne d'indice %d !\n",
		   indice, indicePersonne);
}
/* erreur, il y a superposition de 2 personnes */
static void erreur_superposition(int indiceP_A, int indiceP_B) {
	if (indiceP_B > indiceP_A) {
		int temp = indiceP_A;
		indiceP_A = indiceP_B;
		indiceP_B = temp;
	}
	printf("les personnes d'indices %d et %d se superposent !\n",
		   indiceP_A, indiceP_B);
}
/* definition de verbose, sociabilité de l'utilisateur */
static bool verbose;

#define MAX_CYCLES 200



				// PARTIE LIBRE //
	//statuts possibles des personnes
enum statuts {S_AUCUN, S_NEUTRE, S_MIPHASE, S_CONTAMINE, S_IMMUNISE};

	//informations sur chaque personne
struct infos_personne {
	int pos_y;
	int pos_x;
	int but_y;
	int but_x;
	enum statuts statut;
};



static bool verification_nbSim (int nbSim) {
	if (nbSim <= 0){
		erreur_nbSim (nbSim);
		return false;
	}
	return true;
}



static bool verification_n (int n) {
	if (n <= 1) {
		erreur_taille_monde (n);
		return false;
	}
	return true;
}



static bool verification_nbP (int nbP, int n) {
	if (nbP <= 1 || nbP > pow(n, 2)) {
		erreur_nbP (nbP, n);
		return false;
	}
	return true;
}



static bool check_coordonnees (int personne, int valeur,
							   int min, int max, char *message) {
	if (valeur < min || valeur > max) {
		erreur_indice_ligne_colonne (valeur, personne);
		if (verbose) printf("%s de la personne d'indice %d est %d et doit etre entre\
							%d et %d.\n", message, personne, valeur, min, max );
		return false;
	}
	return true;
}

static bool verification_coordonnees (int i, int n, int pos_y, int pos_x,
									  int but_y, int but_x) {
	if (check_coordonnees (i, pos_y, 0, n-1, "La coordonnee de position Y") == false)
		return false;
	if (check_coordonnees (i, pos_x, 0, n-1, "La coordonnee de position X") == false)
		return false;
	if (check_coordonnees (i, but_y, 0, n-1, "La coordonnee de BUT Y") == false)
		return false;
	if (check_coordonnees (i, but_x, 0, n-1, "La coordonnee de BUT X") == false)
		return false;
	return true;
}



static bool verification_superposition (int i, struct infos_personne personnes[i]) {
	int j = i;
	while (j > 0) {
		if (personnes[i].pos_y == personnes[i-j].pos_y
			&& personnes[i].pos_x == personnes[i-j].pos_x) {
			erreur_superposition(i-j, i);
			return false;
		}
		--j;
	}
	return true;
}



static int initialisation (int *talk_to_me, int *affichage_monde,
						   int *nbSim,int *n, int *nbP) {
		//verbose
	scanf("%d", talk_to_me);
	verbose = *talk_to_me;
	
		//affichage_monde
	if (verbose) {
		printf("Salutations humain ! \nVeux-tu pouvoir admirer ton oeuvre?\n");
	}
	scanf("%d", affichage_monde);
	
		//nbSim
	if (verbose) {
		printf("Combien de fois voudrais-tu contaminer la population?\n");
	}
	scanf("%d", nbSim);
		//erreur_nbSim
	if (verification_nbSim(*nbSim) == false) return EXIT_FAILURE;
	
		//n (taille du monde)
	if (verbose) {
		printf("Quelle est la taille du monde que tu veux contaminer?\n");
	}
	scanf("%d", n);
		//erreur_taille_monde
	if (verification_n (*n) == false) return EXIT_FAILURE;
	
		//nbP
	if (verbose) {
		printf("Combien de personnes habitent ce monde?\n");
	}
	scanf("%d", nbP);
		//erreur_nbP
	if (verification_nbP (*nbP, *n) == false) return EXIT_FAILURE;
	
	return EXIT_SUCCESS;
}



static int lecture_personnes (int nbP, int n, struct infos_personne *personnes) {
		//coordonnees
	if (verbose) {
		printf("Maintenant, entre un par un les emplacements de ces personnes\
			   ainsi que leur but?\n");
	}
	
	int i = 0;
	while (i < nbP) {
		
		scanf("%d %d %d %d",
			  &(personnes[i].pos_y), &(personnes[i].pos_x),
			  &(personnes[i].but_y), &(personnes[i].but_x));
		
			//etat des personnes au depart
		if (i == 0) personnes[i].statut = S_CONTAMINE;
		else personnes[i].statut = S_AUCUN;
		
			//erreur_coordonnees
		if (verification_coordonnees (i, n,
									  personnes[i].pos_y,
									  personnes[i].pos_x,
									  personnes[i].but_y,
									  personnes[i].but_x) == false)
			return EXIT_FAILURE;
		
			//erreur_superposition
		if (verification_superposition (i, personnes) == false) return EXIT_FAILURE;
		
		++i;
	}
	return EXIT_SUCCESS;
}



int main () {
	
	int talk_to_me;
	int affichage_monde;
	int nbSim;
	int n;
	int nbP;
	
	if (initialisation (&talk_to_me, &affichage_monde,
						&nbSim, &n, &nbP) == EXIT_FAILURE) return EXIT_FAILURE;
	
	struct infos_personne personnes[nbP];
	
	if (lecture_personnes (nbP, n, personnes) == EXIT_FAILURE) return EXIT_FAILURE;
	
	printf("\n");
	return EXIT_SUCCESS;
}




/*[][][][][][][][][][][][][][][][][][]*
 
 Pseudocode :
 
 intialisation
 verbose <-- talk_to_me
 affichage_monde
 verification_nbSim
 si nbSim < 0, erreur
 verification_taille_monde
 si taille_monde <= 1, erreur
 verification_nbP
 si nbP <= 1 ou nbP > n*n, erreur
 declaration taille structure (personnes[nbP])
 lecture des coordonnees des personnes
 pour i < nbP
 enregistrer les 4 coordonnees dans la structure
 enregistrer l'etat de depart des personnes dans la structure
 verification_coordonnees
 (petite etape utile durant les test mais pas necessaire)
 si une coordonee est en dehors du monde, erreur
 verification superposition
 si 2 personnes sont au meme endroit, erreur
 fin
 
 *[][][][][][][][][][][][][][][][][][]*/

