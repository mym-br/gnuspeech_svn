
#ifndef JACK_DATA_H_
#define JACK_DATA_H_

#ifdef GNUSTEP

#include <jack/jack.h>
#include <jack/ringbuffer.h>

typedef struct {
	jack_client_t *client;
	jack_port_t *outputPort;
	jack_nframes_t sampleRate;

	// There can only be a single reader and a single writer thread accessing this ringbuffer.
	jack_ringbuffer_t *ringBuffer; // input
} jack_local_data_t;

#define JACK_RINGBUFFER_SIZE (12000 * sizeof(jack_default_audio_sample_t))
#define MIN_LATENCY_NS 20000000
#define JACK_CLIENT_NAME "gssynthesizer"

extern jack_local_data_t jackData;

#endif

#endif /*JACK_DATA_H_*/
