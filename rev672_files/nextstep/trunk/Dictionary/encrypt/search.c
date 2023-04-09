#include <stdio.h>
#include "buffer.h"
#import <streams/streams.h>

/*===========================================================================

	This file contains the Main dictionary search routines. 
	It was written by Craig R. Schock in May, 1990.  Updated May, 1991.

	Any bug reports should be directed to: 
		schock@flip.cpsc.ucalgary.ca

	To compile this file you must also link in a file called
	"Dictionary_Index.o". 

	Before the dictionary can be used, the init_dict() function must be
	called. 

	To use the dictionary, use the search function.
	Syntax:  
		search(word) 
		where "word" is a (char *) to the word to be searched.

===========================================================================*/


#define MAX_COUNT 5557
#define ERROR (-1)

/*#define dictionary "/LocalLibrary/Speech/MainDictionary"*/
/*#define dictionary "/Accounts/schock/.speechlibrary/converted_index"*/
#define dictionary "./dictionary"

unsigned int hash[4],hashval,hashcalc();	/* Hashes are unsigned */

extern int size[];				/* From index file */
extern unsigned int *trees[];			/* From index file */
char final[256];				/* Resulting buffer */


NXStream *fp;
char *search();					/* Declare search to return string */

/*===========================================================================*/
/*                          START of Debugging Code                          */
/*===========================================================================*/

main()
{
char line[100];
char *temp;
register int i;


	init_dict();
	printf("Please enter a word (lower case)\n> "); fflush(stdout);
	while(fgets(line, 100, stdin)!=0)
	{
		for (i = 0;i<strlen(line);i++) if (line[i]<'A') line[i] = '\000';
		temp = search(line);
		if (temp==NULL)
		{
/*			print_whole_tree();*/
			printf("NULL POINTER FROM SEARCH\n");
		}
		else
			printf("word: %s\n",temp);
		printf("Please enter a word (lower case)\n> "); fflush(stdout);

	}
	NXClose(fp);
}


print_whole_tree()
{
int i;
char line[256];
long offset;
unsigned int *pointer;

	pointer = (unsigned int *) trees[hashval];
	if (pointer == NULL) return(ERROR);


	for (i = 0;i<size[hashval];i++)
	{
		offset = (pointer[i]>>10)&0x3FFFFF;
		NXSeek(fp,offset,NX_FROMSTART);
		NXScanf(fp,"%s",line);
		printf("offset: %d  Hash : %x  line: |%s|\n",offset, ((pointer[i]&0x3FF)), line);
	}
	printf("hashval: %d     1: %x  2: %x  3: %x  4: %x\n", hashval, hash[0],hash[1],hash[2],hash[3]);

}


/*===========================================================================*/
/*                            END of Debugging Code                          */
/*===========================================================================*/

init_dict()
{

	fp = NXMapFile(dictionary, NX_READONLY);	/* Map file into memory */
	if (fp==NULL)					/* exit if file not found */
	{
		printf("Cannot open Dictionary File\n");
		exit(0);
	}

}

char *search(word)
/*===========================================================================

	Function: search

	Parameter: (char *) word	NULL terminated

	Purpose: This function searches the main dictionary for the word
		specified in the parameter "word".

	Returns: If the word is found, this function returns a pointer to 
		a buffer which contains the pronunciation.  If the word is 
		not found, this function returns a NULL

	Algorithm: To compile this program, you must include the file
		"Dictionary_Index.o".  This file contains the data structures
		which define the index to the main dictionary file.  
		This function traverses those structures to find the correct
		entry in the dictionary.

		NOTE:  If the main dictionary is changed, "Dictionary_Index.o"
		must be re-compiled.  All programs which use this file must
		also be re-compiled with the new index.  Since the main
		dictionary is not to be changed, this is a reasonable 
		limitation.

		For a description of the index data structures see the 
		descriptions file.

===========================================================================*/
char *word;
{
int i;
char line[256],dummy[256];
long offset;

	final[0] = '\000';					/* Initialize buffer */
	hashval = hashcalc(word)%(unsigned int)MAX_COUNT;	/* Main hash for word */
	for(i = 0;i<4;i++)					/* Max 4 traversals */
	{
		offset = get_offset(hashval,hash[i]);		/* Find the offset into
								the dictionary file for this
								given word */

		if ((offset == ERROR)&&(i>=3)) 			/* return null if word not found */
			return((char *) NULL);
		else
		if (offset != (-1))
		{
			NXSeek(fp,offset,NX_FROMSTART);		/* seek to word */
/*			NXScanf(fp,"%s %s",dummy,final);	/* read word and pronunciation */
			decrypt(offset, dummy, final);
			printf("|%s|  |%s|\n", dummy, final);
			if (strcmp(dummy,word)==0)		/* Compare */
			{
				strcat(final,"%");		/* If ok, return word */
				break;
			}
			if (i>=3) return((char *) NULL);
		}
	}
	return(final);
}

unsigned int hashcalc(word)
/*===========================================================================

	function: hashcalc

	Parameter: (char *) word		NULL terminated

	Purpose: This function calculates 5 hash functions for the word 
		passed in the parameter "word". 
	Returns: (unsigned int) hash.  

	Global Variables: hash[4].  These are global for speed reasons.

	Algorithm: The main hash is a simple folding hash.  The remaining
		hashes simply attempt to differentiate words based on 
		different properties.

===========================================================================*/
	

char *word;
{
int i;
int retval;

	hash[0] =  hash[1] = hash[2] = hash[3] = 0; 	/* Initialize */
	retval = strlen(word);
	hash[0] = ( (int)word[0]+ (int) word[1])*retval;
	hash[1] = (int) word[0]* (int) word[retval-1];
	for(i = 0;i<strlen(word);i++)
	{
		hash[2]+= (int) word[i];
		hash[3] = hash[2]*hash[2]* (int) word[i] * i;
		retval *= (int) word[i];
	}
	hash[0] = (hash[0]%1021);
	hash[1] = (hash[1]%1021);
	hash[2] = (hash[2]%1021);
	hash[3] = (hash[3]%1021);
	if (retval<0) retval *=(-1);
	return(retval);

}

get_offset(hash,number)
/*===========================================================================

	function: get_offset

	Parameter: hash : tree index pointer
		   number: key to search for in binary tree

	Purpose: This function returns the file index where the word is 
		suspected to be.  The index is taken out of the index 
		data structure.

	Returns: (int) index into main dictionary file
		 (int) (-1) error.

	Algorithm: Since the binary search trees are implemented in arrays,
		this function simply traverses those trees looking for the 
		key passed in the "number" parameter.  

	Statistics: The following are statistics generated from the 
		index file generation program.

	Hash1 = 94183	: # of words found on first attempt
	Hash2 = 4864	: " "   "      "   "  second   "
	Hash3 = 108	: " "   "      "   "  third    "
	Hash4 = 1	: " "   "      "   "  fourth   "

	95 % of all words are found on first attempt.
	4.5 % of all words are found on second attempt.
	0.49 % of all words are found on third attempt.
	0.01 % of all words are found on fourth attempt.

	NOTE: Because HASH values are compared and not strings, the comparison
	operation is much faster.  There is a 1/1021 probability that hash 
	values of different words will match.  Therefore there is only a 1/1021
	probability that an unnecessary seek into the dictionary file
	will take place.

===========================================================================*/
int hash;
int number;
{
unsigned int *pointer;
int go = 0;
int max;
int hashsearch;
int local;

	local = 0;				/* Pointer into tree array */
	max = size[hash];			/* Number of items in the tree */
	pointer = (unsigned int *) trees[hash];	/* Get pointer to tree */
	if (pointer == NULL) return(ERROR);	/* If tree does not exist, return an error */
	while(1)				/* Go until found or out of data structure bounds */
	{
						/* If the hash values match, return the index */
		if (number == (pointer[local]&0x3FF)) return((pointer[local]>>10) & 0x3FFFFF);
		if (number<(pointer[local]&0x3FF)) go = 0;
		else go = 1;
		switch(go)
		{
			case 0: local = local*2+1;		/* Take left branch */
				if (local>max) return(ERROR);	/* If passed tree bounds,
								   return error */
				break;
			case 1:
			default: local = local*2+2;		/* take right branch */
				if (local>max) return(ERROR);
				break;
		}
	}
}


decrypt(offset, dummy, final)
int offset;
char *dummy, *final;
{
int temp;
int index = (offset%256), i;

	i = 0;
	while(1)
	{
		temp = NXGetc(fp);
		temp = temp-buffer[index];
		index = (index+1)%256;
		if (temp<0) temp+=256;
		if (temp == 0x20) break;
		dummy[i++] = (char) temp;
		if (i>=255) break;
	}
	dummy[i] = '\000';
	i = 0;
	while(1)
	{
		temp = NXGetc(fp);
		temp = temp-buffer[index];
		index = (index+1)%256;
		if (temp<0) temp+=256;
		if (temp == 0x0a) break;
		final[i++] = (char) temp;
		if (i>=255) break;
	}
	final[i] = '\000';

}
