'''
    randomgain.py
    Add a random gain on wave audio
'''
import numpy as np
import matplotlib.pyplot as plt
import sys, getopt, math
import yaml

# Constants
# Help message
HELP_MESSAGE = '''Add a random gain on the audio file.
Usages:randomgain.py -c <config_file> -o <output_file>
    -c <config_file>
        Specify the config filename.
    -o <output_file>
        Specify the output filename.
    -h
        Display this help message.
'''

def add_noise(sig, noise, snr):
    signalPower = np.sum(np.abs(sig) ** 2)
    noisePower = np.sum(np.abs(noise) ** 2)
    noisePowerNew = signalPower / (10 ** (snr / 10))

    noise = noise * np.sqrt(noisePowerNew / noisePower)

    return sig + noise

def generate_sine(ampl, freq, len):
    x = np.linspace(0, len, len)
    return ampl * np.sin(2 * math.pi / freq * x)

if __name__ == '__main__':
    # Parse the arguments
    opts, args = getopt.getopt(sys.argv[1:], "hc:o:")

    for opt,val in opts:
        if opt == '-c':
            config_file = val
        elif opt == '-o':
            output_file = val
        else:
            print(HELP_MESSAGE)
            sys.exit()

    # Read parameters from config file
    with open(config_file, 'r') as f:
        config = yaml.load(f, Loader = yaml.FullLoader)
    
    SAMPLERATE = config['samplerate']
    LENGTH = config['length']
    OUTFILE = config['output-file']
    SPECTRUMS = config['spectrum']

    NOISE_INFO = config['noise']

    QUANT = config['quant']

    # Generate spectrum
    data = np.zeros(int(LENGTH), dtype = np.float32)
    for v in SPECTRUMS:
        data += generate_sine(v['ampl'], v['freq'] * SAMPLERATE, int(LENGTH))

    # Add noise
    # Generate white noise and add to data
    if NOISE_INFO['enable']:
        white_noise = np.random.uniform(0, 1, LENGTH)
        data = add_noise(data, white_noise, NOISE_INFO['snr'])

    # Normalize
    mx = np.max(data)
    data = data / mx
    
    # Apply gain on the curve
    print('Converting to fixed point...')
    data = data * (pow(2, QUANT) - 1)
    data = data.astype(np.int16)
    data = data.tolist()
    data = '\n'.join([('%04x' % v) for v in data])

    # Save wave audio
    print('Saving the file...')
    with open(output_file, 'w') as f:
        f.write(data)

    print('Done.')