#include <stdio.h>
#include "list.h"
#include "s.h"

/*#define MAX_COUNT 2999*/
#define MAX_COUNT 5557
#define ERROR (-1)

/*#define dictionary "/Accounts/schock/.speechlibrary/converted_index"*/
char dictionary[256];

int current_count = 0;
int buffer[256];
int node_count;
int *align_tree();
unsigned int hash1,hash2,hash3,hash4;
int vhash1 = 0, vhash2 = 0, vhash3 = 0, vhash4 = 0;

unsigned int hash();

int amount[MAX_COUNT];
FILE *fp;


struct list_node dummy,*find_spot();
struct list_node *nodes[MAX_COUNT];
int *list_to_array();

main(argc, argv)
int argc;
char *argv[];
{
	if (argc!=2) 
	{
		fprintf(stderr,"Usage: %s dictionary_file\n", argv[0]);
		exit(1);
	}
	else
		strcpy(dictionary, argv[1]);

	bzero(&nodes[0], sizeof(struct list_node *) * MAX_COUNT);
	fprintf(stderr,"Creating Lists\n");
	make_lists();
	fprintf(stderr,"Converting lists to trees\n");
	convert_tree();
	set_head_list();
	print_amounts();
	fprintf(stderr,"Completed\nHash1 = %d\nHash2 = %d\nHash3 = %d\nHash4 = %d\n", vhash1, vhash2, vhash3, vhash4);
}

insert_node(tree,hash,value,hnum)
int tree,hash,value,hnum;
{
register struct list_node *node,*prev,*current;
int ins = 0;
unsigned int final_val;

/*	if (hnum == 3) fprintf(stderr,"hash Number 3\n");
	if (hnum == 4) fprintf(stderr,"hash Number 4\n");*/
	node = nodes[tree];
	prev = node;

	final_val = ((value & 0x3FFFFF)<<10) | (hash & 0x3FF) ;

	if (node ==NULL) 
	{
		node = (struct list_node *) malloc(sizeof(struct list_node));
		node -> hash = hash;
		node -> value = final_val;
		node -> next = NULL;
		nodes[tree] = node;
		amount[tree] = amount[tree]+1;
	}
	else
	{
		current = (struct list_node *) malloc(sizeof (struct list_node));
		current -> value = final_val;
		current -> hash = hash;
		current -> next = NULL;
		while(node!=NULL)
		{
			if (node->hash == hash) return(ERROR);
			if(node->hash>hash)
			{
				if (node == nodes[tree])
				{
					current->next = node;
					nodes[tree] = current;
					node = NULL;
					amount[tree] = amount[tree]+1;
					ins = 1;
					break;
				}
				else
				{
					current->next = node;
					prev -> next = current;
					node = NULL;
					amount[tree] = amount[tree]+1;
					ins = 1;
					break;
				}
			}
			else
			{
				prev = node;
				node = node->next;
			}
		}
		if (ins == 0)
		{
			amount[tree] = amount[tree]+1;
			prev->next = current;
		}
	}
}

convert_tree()
{
int i;
int *array_list;

	for (i = 0;i<MAX_COUNT;i++)
	{
		node_count = 0;
		array_list = list_to_array(nodes[i]);
		array_to_tree(array_list, node_count,i);
	}
}

set_head_list()
{
int i;
int format = 0;
	printf("static char *dummy = \"@(#) Tree Construction by Craig R. Schock. Trillium 1990.\";\n");
	printf("unsigned int *trees[%d] = {",MAX_COUNT);
	for (i = 0;i<MAX_COUNT-1;i++)
	{
		if (format >= 10) 
		{
			printf("\n\t");
			format = 0;
		}
		else format++;
		printf("tree%d,",i);
	}
	printf("tree%d",MAX_COUNT-1);
	printf("};\n");
}

int *list_to_array(root)
struct list_node *root;
{
int i = 0;
	while(root!=NULL)
	{
		buffer[i] = root->value;				/* Change here to see sequence hash */
		i++;
		node_count++;
		root = root->next;
	}
	return(buffer);
}

array_to_tree(list,count,number)
int *list;
int count,number;
{
register int *seq;
register int i;
int buf[256],place[256];

	for (i = 0;i<256;i++) { buf[i] = (-1); place[i] = (-1); }
	seq = (int *) get_seq(count);
	for(i = 0; i<count; i++)
	{
		insert_tree(buf,place,list[seq[i]-1],seq[i]-1);
	}
	printf("static unsigned int tree%d[%d] = { ",number, count);
	for(i = 0; i<count; i++)
	{
		printf("0x%X",buf[i]);
		if (i!=count-1) printf(",");
	}
	printf("};\n");
	fflush(stdout);
}

insert_tree(buf,place,number,seq)
int *buf,*place;
int number,seq;
{
int where = 0;

/*	fprintf(stderr,"Inserting %d and %d\n",seq,number);*/
	while(buf[where] != (-1))
	{
/*		fprintf(stderr, "Where = %d, Buf[where] = %d\n",where,buf[where]);*/
		if (place[where]>seq) where = where*2+1;
		else where = where*2+2;
	}
	buf[where] = number;
	place[where] = seq;

}

/*================================================================================*/

error_file(string)
char *string;
{
	printf("Could not open file \"%s\" for writing\n",string);
	exit(1);
}

error_malloc(value)
int value;
{
	printf("Could not malloc %d bytes\n",value);
	exit(1);
}

make_lists()
{
FILE *dict;
char line[256],word[100];
int offset;
unsigned int x;
char dummy[256];
int line_count = -1;

	dict = fopen(dictionary,"r");
	if (dict == NULL) return(0);
	version(dict);
	offset = ftell(dict);
	while(fgets(line, 256, dict)!=NULL)
	{
		line_count++;
		if (line[0]>'9')
		{
			sscanf(line, "%s %s",word, &dummy);
			x = hash(word) % (unsigned int) MAX_COUNT;
			if (insert_node(x,hash1,offset,0) == ERROR)
			{
			  if (insert_node(x,hash2,offset,1) == ERROR)
			  {
			    if (insert_node(x,hash3,offset,2) == ERROR)
			    {
				fprintf(stderr,"4th hash: Word = %s\n",word);
				if (insert_node(x,hash4,offset,3) == ERROR) 
				{
					fprintf(stderr,"Collision error!! %s %d\n",word,x);
/*					exit(0);*/
			        } else vhash4++;
			    } else vhash3++;
			  } else vhash2++;
			} else vhash1++;
		}
		
		offset = ftell(dict);
	}
}

unsigned int hash(word)
char *word;
{
int i;
int retval;

	hash1 = 0; hash2 = 0; hash3 = 0; hash4 = 0;
	retval = strlen(word);
	hash1 = ( (int)word[0]+ (int) word[1])*retval;
	hash2 = (int) word[0]* (int) word[retval-1];
	for(i = 0;i<strlen(word);i++)
	{
		hash3+= (int) word[i];
		hash4 = hash3*hash3* (int) word[i] * i;
		retval *= (int) word[i];
	}
	hash1 = hash1%1021;
	hash2 = hash2%1021;
	hash3 = hash3%1021;
	hash4 = hash4%1021;
	if (retval<0) retval *=(-1);
	return(retval);

}

print_amounts()
{
int i;
int format = 0;

	printf("int size[%d] = {",MAX_COUNT);
	for (i = 0; i<MAX_COUNT-1;i++)
	{
		printf("%d,",amount[i]);
		if (format>=40)
		{
			format = 0;
			printf("\n");
		}
		else format++;
	}
	printf("%d};\n",amount[i]);
}

version(fp)
FILE *fp;
{
char line[256];
int index = 0;

	fgets(line, 256, fp);
	while(line[index]>=' ') index++;
	line[index] = '\000';
	printf("static char DictionaryVersion[] = \"%s\";\n", line);
	printf("char *CompiledDictionaryVersion()\n");
	printf("{\n");
	printf("\treturn(DictionaryVersion);\n");
	printf("}\n");
	fflush(stdout);

}