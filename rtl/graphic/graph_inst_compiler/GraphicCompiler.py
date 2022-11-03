'''
    GraphicCompiler.py
    Graphic Compiler
'''
from tabnanny import verbose
from GraphicInstructions import GIBox, GIString, GIJump, GIChart, GIWrite

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
                print(v.hint(p))

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

if __name__ == '__main__':
    g = GraphicCompiler(True)

    g.label('main:')
    g.add(GIString(10,20,30,'Hello world!', 255, 0, 1).get())
    g.add(GIBox(10, 10, 800, 600, 255, 0).get())
    g.add(GIWrite().get())
    g.add(GIJump(label = 'main').get())

    g.map_data()
    g.compile()

    print(g.get_machine_code())
    print(g.get_mapped_data())