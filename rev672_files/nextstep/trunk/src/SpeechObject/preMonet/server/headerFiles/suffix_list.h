/***********************************************************************

A list of suffixes to look for when searching in the main dictionary.
The following steps are taken when a word is not found in the
dictionary:

The "suffix" field is a suffix to identify.  If that suffix is
present, it is replaced with the contents of the "replacement" field,
and searched for again.  If found, the pronunciation returned from the
dictionary is augmented with the contents of the "pronunciation"
field, and returned as the pronunciation of the word.  Otherwise, the
other suffixes in this list are tried in order.  If none match, we
assume that no inflected form of the word is in the dictionary, and we
return NULL.

The list is organized with more specific cases first, falling through
to the more general ones.

There are certain exceptions that cannot be handled and should be put
in the dictionary.  Example: "houses".

These SHOULD be ordered according to frequency, for speed.  However,
note the importance of keeping more specific cases first.  (The linear
order adopted here is a total ordering of the poset formed by this
requirement, and could be optimized as such.)

***********************************************************************/


/*  DATA TYPES  *******************************************************/

struct SL {
    char *suffix;
    char *replacement;
    char *pronunciation;
};
typedef struct SL suffix_list_t;



/*  SUFFIX LIST  ******************************************************/

static suffix_list_t suffix_list[] = {
  {"ses","se",".uh_z"},	   //  example: "horses" = "horse" + "es"
  {"ces","ce",".uh_z"},	   //  example: "spices" = "spice" + "es"

/* 
 *  The next two are WRONG for voiced preceding cons, or preceding vowel;
 *  e.g. "candies", "ranges", "bids". Must add all relevant cases.
 *  {"es","e","_s"},	       example: "bites" = "bite" + "s"
 *  {"s","","_s"},	       example: "baits" = "bait" + "s"
 *
 *  The following fixes this:
 */

  {"aes","ae","_z"},
  {"bes","be","_z"},
  {"des","de","_z"},
  {"ees","ee","_z"},
  {"fes","fe","_s"},
  {"ges","ge",".uh_z"},
  {"ies","y","_z"},
  {"kes","ke","_s"},
  {"les","le","_z"},
  {"mes","me","_z"},
  {"nes","ne","_z"},
  {"oes","oe","_z"},
  {"pes","pe","_s"},
  {"res","re","_z"},
  {"tes","te","_s"},
  {"ues","ue","_z"},
  {"ves","ve","_z"},
  {"wes","we","_z"},
  {"xes","x",".uh_z"},
  {"yes","ye","_z"},
  {"zes","ze","_z"},

  {"as","a","_z"},
  {"bs","b","_z"},
  {"cs","c","_s"},
  {"ds","d","_z"},
  {"es","e",".uh_z"},	   //  because all other cases were caught above
  {"fs","f","_s"},
  {"gs","g","_z"},
  {"hs","h","_s"},	   //  e.g. "baths" pronounced "ba(theta)s" 
  {"is","i","_z"},
  {"ks","k","_s"},
  {"ls","l","_z"},
  {"ms","m","_z"},
  {"ns","n","_z"},
  {"os","o","_z"},
  {"ps","p","_s"},
  {"qs","q","_s"},	   //  "there are many Iraqs in the world today..."
  {"rs","r","_z"},
  {"ts","t","_s"},
  {"us","u","_z"},
  {"vs","v","_z"},	   //  how many words in dict. that end in "v"? "revs"?
  {"ws","w","_z"},
  {"ys","y","_z"},

  {"iest","y",".uh_s_t"},  //  example: "heaviest" = "heavy" + "est"
  {"bbest","b",".uh_s_t"}, //  example: "drabbest" = "drab" + "est"
  {"ddest","d",".uh_s_t"}, //  example: "baddest" = "bad" + "est"
  {"ggest","g",".uh_s_t"}, //  example: "biggest" = "big" + "est"
  {"mmest","m",".uh_s_t"}, //  example: "slimmest"
  {"nnest","n",".uh_s_t"}, //  example: "thinnest"
  {"ppest","p",".uh_s_t"}, //  example: "flippest" = "flip" + "est"
  {"ttest","t",".uh_s_t"}, //  example: "hottest"
  {"est","e",".uh_s_t"},   //  example: "largest" = "large" + "est"
  {"est","",".uh_s_t"},	   //  example: "hardest" = "hard" + "est"
  {"ing","e",".i_ng"},	   //  example: "bouncing" = "bounce" + "ing"
  {"ing","",".i_ng"},	   //  example: "eating" = "eat" + "ing"
  {"lled","l","_d"},	   //  example: "jewelled" = "jewel" + "d"
  {"rred","r","_d"},	   //  example: "sparred" = "spar" + "d"
  {"bbed","b","_d"},	   //  example: "bobbed" = "bob" + "d"
  {"dded","d",".uh_d"},	   //  example: "padded" = "pad" + "ed"
  {"gged","g","_d"},	   //  example: "bagged" = "bag" + "d"
  {"mmed","m","_d"},	   //  example: "slammed" = "slam" + "d"
  {"nned","n","_d"},	   //  example: "gunned" = "gun" + "d"
  {"pped","p","_t"},	   //  example: "flipped" = "flip" + "t"
  {"tted","t",".uh_d"},	   //  example: "batted" = "bat" + "ed"
  {"ded","de",".uh_d"},	   //  example: "slided" = "slide" + "ed"
  {"ded","d",".uh_d"},	   //  example: "added" = "add" + "ed"
  {"ted","te",".uh_d"},	   //  example: "spited" = "spite" + "ed"
  {"ted","t",".uh_d"},	   //  example: "waited" = "wait" + "ed"
  {"ed","e","_t"},	   //  example: "faced" = "face" + "t"
  {"ed","","_t"},	   //  example: "walked" = "walk" + "t"
  {"er","e",".er"},	   //  example: "slider" = "slide" + "er"
  {"ller","l",".uh_r"},	   //  example: "jeweller" = "jewel" + "er"
  {"rrer","r",".uh_r"},	   //  example: "sparrer" = "spar" + "er"
  {"bber","b",".uh_r"},	   //  example: "bobber" = "bob" + "er"
  {"dder","d",".uh_r"},	   //  example: "padder" = "pad" + "er"
  {"gger","g",".uh_r"},	   //  example: "bagger" = "bag" + "er"
  {"mmer","m",".uh_r"},	   //  example: "slammer" = "slam" + "er"
  {"nner","n",".uh_r"},	   //  example: "runner" = "run" + "er"
  {"pper","p",".uh_r"},	   //  example: "flipper" = "flip" + "er"
  {"tter","t",".uh_r"},	   //  example: "batter" = "bat" + "er"
  {"lling","l",".i_ng"},   //  example: "quarrelling" = "quarrel" + "ing"
  {"rring","r",".i_ng"},   //  example: "starring" = "star" + "ing"
  {"bbing","b",".i_ng"},   //  example: "bobbing" = "bob" + "ing"
  {"dding","d",".i_ng"},   //  example: "padding" = "pad" + "ing"
  {"gging","g",".i_ng"},   //  example: "bagging" = "bag" + "ing"
  {"mming","m",".i_ng"},   //  example: "slamming" = "slam" + "ing"
  {"nning","n",".i_ng"},   //  example: "running" = "run" + "ing"
  {"pping","p",".i_ng"},   //  example: "flipping" = "flip" + "ing"
  {"tting","t",".i_ng"},   //  example: "batting" = "bat" + "ing"
  {(char *)0,(char *)0,(char *)0}     //  END MARKER
};
