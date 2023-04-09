static char file_id[] = "@(#)Normal Distribution. Author: Craig-Richard Schock. (C) Trillium, 1991, 1992.";

static float input[25] = {0.00000, 0.00003, 0.00135, 0.00621, 0.02275, 0.06681,
	0.11507, 0.15866, 0.21186, 0.27425, 0.34458, 0.42074, 0.50000, 0.57926,
	0.65542, 0.72575, 0.78814, 0.84134, 0.88493, 0.93319, 0.97725, 0.99379,
	0.99865, 0.99997, 1.0
};


static float output[25] = {-5.0, -4.0, -3.0, -2.5, -2.0, -1.5,
	-1.2, -1.0, -0.8, -0.6, -0.4, -0.2, 0.0, 0.2, 0.4,
	0.6, 0.8, 1.0, 1.2, 1.5, 2.0, 2.5, 3.0, 4.0, 5.0
};

float gaussian();

/*main()
{
register int i;

	for (i = 0;i<10000;i++)
		printf("%f\n",gaussian());
}	
*/

float gaussian()
{
register int i;
long random();
float value;

	value = (float)((float) random() /0x7FFFFFFF);
	for (i = 0;i<25; i++)
		if (value<=input[i]) return(output[i]/5.0);

	return(output[24]);
}
