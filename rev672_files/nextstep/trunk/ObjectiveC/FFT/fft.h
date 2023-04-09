/* fft.c */
int fft(struct _FFTheader *fftStruct);
int do_fft(SNDSoundStruct *SNDheader, struct _FFTheader *FFTheader);
int prepare_window(short int *buffer, int index, float *window, int maxSamples);
int four1(float *data, int nn, int isign);
int write_header(struct _FFTheader *fftStruct);
int write_results(float *window);
int make_hanning(void);
int make_kbWindow(void);
int usage(char *string);
int main(int argc, char *argv[]);
