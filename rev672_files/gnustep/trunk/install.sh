#/bin/bash
# This script will build and install GnuSpeech in ~/GNUstep.

set -e

base_dir=$PWD

cd Frameworks/Tube
make debug=no
make install GNUSTEP_INSTALLATION_DOMAIN=USER
cd "$base_dir"

cd Frameworks/GnuSpeech
make debug=no
make install GNUSTEP_INSTALLATION_DOMAIN=USER
cd "$base_dir"

cd Applications/Monet
make debug=no
make install GNUSTEP_INSTALLATION_DOMAIN=USER
cd "$base_dir"

cd Applications/PreMo
make debug=no
make install GNUSTEP_INSTALLATION_DOMAIN=USER
cd "$base_dir"

cd Tools/GnuSpeechCLI
make debug=no
make install GNUSTEP_INSTALLATION_DOMAIN=USER
cd "$base_dir"

cd Applications/Synthesizer
make debug=no
make install GNUSTEP_INSTALLATION_DOMAIN=USER
cd "$base_dir"

echo === Ok.
