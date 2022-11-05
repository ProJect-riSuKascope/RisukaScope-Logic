'''
    random_coeff_gen.py
'''
import random

length = 1024
numerator = 8
output_file = 'recv_comp.mem'

if __name__ == '__main__':
    li = []
    for i in range(length):
        v = int(random.random() * pow(2, numerator))

        li.append(hex(v)[2:])
    
    # Dump to memory file
    s = '\n'.join(li)
    with open(output_file, 'w') as f:
        f.write(s)