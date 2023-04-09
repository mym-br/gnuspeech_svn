#include <stdio.h>

typedef unsigned char byte;


/*new_phone(byte token, byte foot, byte syllable, byte word);*/


phone_string(string)
char *string;
{
byte syllable,word,salient,marked;
int length, index, tempindex;
char temp[10];

	index = 0;
	length = strlen(string);
	bzero(temp,10);

	syllable = salient = marked = (byte)0;
	word = (byte)1;

	while(index<length)
	{

		if (string[index] == '\n') index++;
		if (index>=length) break;
		while(string[index] == ' ')
		{
			index++;
			word = (byte)1;
			syllable = (byte)1;
		}

		if (string[index] == '/')
			index = handle_slash(string, index, &marked, &salient);

		while((string[index] == ' ') || (string[index] == '_'))
		{
			index++;
			if (string[index]==' ') 
			{
				word = (byte)1;
				syllable = (byte)1;
			}
		}

		if (string[index] == '.')
		{
			index++;
			syllable = (byte)1;
		}
		if (string[index] == '\'') 
		{
			salient = (byte)1;
			index++;
		}

		if (marked == (byte)1)
		{
			temp[0] = '\'';
			tempindex = 1;
		}
		else tempindex = 0;

		while( ((string[index]>='a')&&(string[index]<='z')) || (string[index] == '^'))
			temp[tempindex++] = string[index++];

		temp[tempindex] = '\000';

		printf("phone = %s  syllable = %d  salient = %d  word = %d  marked = %d\n", 
			temp, (int) syllable, (int) salient, (int) word, (int) marked);

		syllable = salient = word = (byte)0;
	}


}

handle_slash(string, index, marked, salient)
char *string;
int index;
byte *marked, *salient;
{
int done = 0;
int new_index = 0;

	while(!done)
	{
		switch(string[index+1])
		{
			case '*': index +=2;
				  *salient = (byte) 1;
				  *marked = (byte)1;
				  break;
			case '/': index +=2;
				  *marked = (byte)0;
				  break;
			case '_': index +=2;
				  *salient = (byte) 1;
				  *marked = (byte)0;
				  break;
			case '0': index +=2;
				  printf("Tone group 0\n");
				  break;
			case '1': index +=2;
				  printf("Tone group 1\n");
				  break;
			case '2': index +=2;
				  printf("Tone group 2\n");
				  break;
			case '3': index +=2;
				  printf("Tone group 3\n");
				  break;
			default : index++;
				  break;
		}
		new_index =  look_ahead(string, index);
		if (new_index==0) done = 1;
		else index = new_index;
	}

	return(index);
}

look_ahead(string, index)
char *string;
int index;
{
int temp;
	temp = strlen(&string[index]);
	while(index<temp)
	{
		if (string[index] == '/') return(index);
		if ( (string[index]>='a')&&(string[index]<='z')) break;
		index++;
	}
	return (0);

}

