'''
    display_spectrum.py
    Display spectrum of a given file

    Copyright 2022 Hiryuu T. (PFMRLIB)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
'''
from scipy.fft import fft
import matplotlib.pyplot as plt
import numpy as np
import sys, getopt
import yaml

# Constants
# Help message
HELP_MESSAGE = '''Spectrum Analysis Tool
    -i <data_file>
        Specify the name of data file.
    -c <config_file>
        Specify the config filename.
    -h
        Display this help message.
'''

def readDataFile(fp):
    with open(fp, 'r') as f:
        src = f.readlines()
    
    # Convert data value to integer
    dst = []
    for i in range(len(src)):
        if src[i][:2] != '//':
            dst.append(int(src[i], 16))
    
    dst = np.array(dst, dtype = np.int16)
    dst = dst.astype(np.float32)

    return dst

def plot(values, title, ylabel):
    l = len(values)
    x = np.linspace(0, l, len(values))

    plt.title(title)
    plt.xlabel('')
    plt.ylabel(ylabel)

    plt.plot(x, values)

def normalize(seq):
    max = np.max(seq)
    seq = seq / max

    return seq

if __name__ == '__main__':
    # Parse the arguments
    opts, args = getopt.getopt(sys.argv[1:], "hi:c:")

    for opt,val in opts:
        if opt == '-i':
            input_file = val
        elif opt == '-c':
            config_file = val
        else:
            print(HELP_MESSAGE)
            sys.exit()

    # Read parameters from config file
    with open(config_file, 'r') as f:
        config = yaml.load(f, Loader = yaml.FullLoader)
    
    SAMPLERATE = config['samplerate']
    SPECTRUMS = config['spectrum']

    # Find the maximum frequency
    max_freq = 0
    for v in SPECTRUMS:
        if v['freq'] > max_freq:
            max_freq = v['freq']

    # Read data files
    data = readDataFile(input_file)
    # Normalize
    data = normalize(data)
    # Do FFT
    spect = np.abs(fft(data))

    # Plot data
    plt.subplot(211)
    plot(data[:int(SAMPLERATE * max_freq)], 'Time Domain', 'Value')
    plt.subplot(212)
    plot(spect[:int(SAMPLERATE / 2)], 'Spectrum', 'Value')
    plt.show()