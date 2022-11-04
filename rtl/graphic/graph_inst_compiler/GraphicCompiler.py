'''
    GraphicCompiler.py
    Graphic Compiler
'''
import sys, getopt, os
import importlib
from GraphicInstructions import GIBox, GIString, GIJump, GIWrite

# Pseudo instructions

class GraphicCompiler():
    instructions = []
    inst_str = ''
    data = ''
    labels = {}

    iptr: int = 0
    dptr: int = 0

    def __init__(self, verbose) -> None:
        self.verbose = verbose

    def add(self, inst):
        '''Add an instruction'''
        # Append instruction
        self.instructions.append(inst)
        self.iptr += inst.inst_len

    def label(self, label):
        self.labels[label] = self.iptr

    def map_data(self):
        for v in self.instructions:
            if not v.data is None:
                v.data_addr = self.dptr

                if self.verbose:
                    print(f'DATA {self.dptr} {v.data}')

                self.data += v.data.encode('ascii').hex('\n')
                self.dptr += len(v.data)

    def compile(self):
        p = 0

        for v in self.instructions:
            if v is type(GIJump) and not v.label == '':
                v.dest_addr = self.labels[v.label]
            
            inst = v.compile()

            if(self.verbose):
                print( v.hint('%08x' % p ))

            self.inst_str += str(hex(inst[0]))[2:] + '\n'
            if(v.inst_len == 1):
                p = p + v.inst_len
                continue

            self.inst_str += str(hex(inst[1]))[2:] + '\n'
            if(v.inst_len == 2):
                p = p + v.inst_len
                continue

            self.inst_str += str(hex(inst[1]))[2:] + '\n'
            
            # Set pointer    
            p = p + v.inst_len

    def get_machine_code(self):
        return self.inst_str

    def get_mapped_data(self):
        return self.data

    def dump_mapped_data(self, fp):
        with open(fp, 'w', encoding = None) as f:
            f.write(self.data)

    def dump_machine_code(self, fp):
        with open(fp, 'w', encoding = None) as f:
            f.write(self.inst_str)

HELP_MESSAGE = '''Graphic Compiler
Usage: python GraphicCompiler.py -i <input_file> -o <output_file> -d <data_file> [-v] [-h]'''

if __name__ == '__main__':
    # Parse the arguments
    opts, args = getopt.getopt(sys.argv[1:], "hvi:o:d:")

    for opt,val in opts:
        if opt == '-i':
            t = os.path.split(val)

            if t[0] == '':
                input_path = '.'
            else:
                input_path = t[0]
            input_module = t[1][:-3]
        elif opt == '-o':
            output_file = val
        elif opt == '-d':
            data_file = val
        elif opt == '-v':
            verbose = True
        else:
            print(HELP_MESSAGE)
            sys.exit()

    m = importlib.import_module(input_path, input_module)

    g = GraphicCompiler(verbose)
    
    for v in m.insts:

        if isinstance(v, str):
            g.label(v)
        else:
            g.add(v)

    g.map_data()
    g.compile()

    g.dump_machine_code(output_file)
    g.dump_mapped_data(data_file)