#define BINARY	 	(0)
#define OTHER		(0)
#define LETTERT		(1)
#define LETTERH		(2)
#define LETTERE		(3)
#define VOWEL		(4)
#define WHITESPACE	(5)

int mappingBuffer[256] = {

BINARY,		/* 00 nul */
BINARY,		/* 01 soh */
BINARY,		/* 02 stx */
BINARY,		/* 03 etx */
BINARY,		/* 04 eot */
BINARY,		/* 05 enq */
BINARY,		/* 06 ack */
BINARY,		/* 07 bel */
BINARY,		/* 08 bs  */
WHITESPACE,		/* 09 ht  */
WHITESPACE,		/* 0a nl  */
BINARY,		/* 0b vt  */
BINARY,		/* 0c np  */
WHITESPACE,		/* 0d cr  */
BINARY,		/* 0e so  */
BINARY,		/* 0f si  */
BINARY,		/* 10 dle */
BINARY,		/* 11 dc1 */
BINARY,		/* 12 dc2 */
BINARY,		/* 13 dc3 */
BINARY,		/* 14 dc4 */
BINARY,		/* 15 nak */
BINARY,		/* 16 syn */
BINARY,		/* 17 etb */
BINARY,		/* 18 can */
BINARY,		/* 19 em  */
BINARY,		/* 1a sub */
BINARY,		/* 1b esc */
BINARY,		/* 1c fs  */
BINARY,		/* 1d gs  */
BINARY,		/* 1e rs  */
BINARY,		/* 1f us  */
WHITESPACE,		/* 20 sp  */
BINARY,		/* 21  !  */
OTHER,		/* 22  "  */
OTHER,		/* 23  #  */
OTHER,		/* 24  $  */
OTHER,		/* 25  %  */
OTHER,		/* 26  &  */
OTHER,		/* 27  '  */
OTHER,		/* 28  (  */
OTHER,		/* 29  )  */
OTHER,		/* 2a  *  */
OTHER,		/* 2b  +  */
OTHER,		/* 2c  ,  */
OTHER,			/* 2d  -  */
OTHER,		/* 2e  .  */
OTHER,		/* 2f  /  */
OTHER,		/* 30  0  */
OTHER,		/* 31  1  */
OTHER,		/* 32  2  */
OTHER,		/* 33  3  */
OTHER,		/* 34  4  */
OTHER,		/* 35  5  */
OTHER,		/* 36  6  */
OTHER,		/* 37  7  */
OTHER,		/* 38  8  */
OTHER,		/* 39  9  */
OTHER,		/* 3a  :  */
OTHER,		/* 3b  ;  */
OTHER,		/* 3c  <  */
OTHER,		/* 3d  =  */
OTHER,		/* 3e  >  */
OTHER,		/* 3f  ?  */
OTHER,		/* 40  @  */
VOWEL,		/* 41  A  */
OTHER,		/* 42  B  */
OTHER,		/* 43  C  */
OTHER,		/* 44  D  */
LETTERE,	/* 45  E  */
OTHER,		/* 46  F  */
OTHER,		/* 47  G  */
LETTERH,	/* 48  H  */
VOWEL,		/* 49  I  */
OTHER,		/* 4a  J  */
OTHER,		/* 4b  K  */
OTHER,		/* 4c  L  */
OTHER,		/* 4d  M  */
OTHER,		/* 4e  N  */
VOWEL,		/* 4f  O  */
OTHER,		/* 50  P  */
OTHER,		/* 51  Q  */
OTHER,		/* 52  R  */
OTHER,		/* 53  S  */
LETTERT,	/* 54  T  */
VOWEL,		/* 55  U  */
OTHER,		/* 56  V  */
OTHER,		/* 57  W  */
OTHER,		/* 58  X  */
OTHER,		/* 59  Y  */
OTHER,		/* 5a  Z  */
OTHER,		/* 5b  [  */
OTHER,		/* 5c  \  */
OTHER,		/* 5d  ]  */
OTHER,		/* 5e  ^  */
OTHER,		/* 5f  _  */
OTHER,		/* 60  `  */
VOWEL,		/* 61  a  */
OTHER,		/* 62  b  */
OTHER,		/* 63  c  */
OTHER,		/* 64  d  */
LETTERE,	/* 65  e  */
OTHER,		/* 66  f  */
OTHER,		/* 67  g  */
LETTERH,	/* 68  h  */
VOWEL,		/* 69  i  */
OTHER,		/* 6a  j  */
OTHER,		/* 6b  k  */
OTHER,		/* 6c  l  */
OTHER,		/* 6d  m  */
OTHER,		/* 6e  n  */
VOWEL,		/* 6f  o  */
OTHER,		/* 70  p  */
OTHER,		/* 71  q  */
OTHER,		/* 72  r  */
OTHER,		/* 73  s  */
LETTERT,	/* 74  t  */
VOWEL,		/* 75  u  */
OTHER,		/* 76  v  */
OTHER,		/* 77  w  */
OTHER,		/* 78  x  */
OTHER,		/* 79  y  */
OTHER,		/* 7a  z  */
OTHER,		/* 7b  {  */
OTHER,		/* 7c  |  */
OTHER,		/* 7d  }  */
OTHER,		/* 7e  ~  */
BINARY		/* 7f del */
};

/*===========================================================================

	Note: This is known as the swiss hack.  This state machine looks
for the occurrence of:

	w[Tt][Hh][Ee]w[VOWEL]

where "w" = whitespace.

The word "the" is then converted to the word "thi" which is hacked in 
the dictionary to be pronounced "thee".  This hack REALLY REALLY Sucks but
it had to be done.

===========================================================================*/

int swissTransitionTable[7][6] = 
{
/*        O  T  H  E  V  W
 	  t  t  h  e  o  S 
	  h           w
	  e           e 
	  r           l
*/
	{ 0, 0, 0, 0, 0, 1, },		/* State 0, wait for whitespace */
	{ 0, 2, 0, 0, 0, 1, },		/* State 1, wait for t. Stay if whitespace */
	{ 0, 0, 3, 0, 0, 1, },		/* State 2, wait for h. State 0 if other, 1 if white */
	{ 0, 0, 0, 4, 0, 1, },		/* State 3, wait for e. State 0 if other, 1 if white */
	{ 0, 0, 0, 0, 0, 5, },		/* State 4, wait for whitespace.  0 if other */
	{ 0, 0, 0, 6, 6, 5, },		/* State 5, wait for vowel or LETTERE, 0 if other, 1 if white */
	{ 0, 0, 0, 0, 0, 1, },		/* State 6, rewrite e -> i. */
};
