'''
    CodeblockGenerators.py
    Code Block Generators
'''
import math
from string import Template

class CodeBlockGenerator():
    '''Base class of code block generators.'''
    BLOCK_TEMPLATE: str
    BLOCK_NAME: str

    reg_description: list
    signals: dict

    def __init__(self, desc: list, signals: dict):
        self.reg_description = desc
        self.signals = signals

    def generate(self):
        '''Generate code block'''

    def substitude(self, code_src):
        '''Substitude the flag with code block'''
        d = {self.BLOCK_NAME: self.generate()}

        return Template(code_src).substitute(d)

class RegDefineGen(CodeBlockGenerator):
    '''Register define block generator'''
    BLOCK_NAME = 'reg_field_define'
    BLOCK_TEMPLATE = 'reg [${width}:0] ${name} [0:${count}];\n'

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        s = ''
        for v in self.reg_description:
            d = {
                'width': v['width'] * 8 - 1,
                'count': v['count'] - 1,
                'name': v['name']
            }

            s += Template(self.BLOCK_TEMPLATE).substitute(d)

        return s

class ResetBlockGen(CodeBlockGenerator):
    '''Register reset block generator'''
    BLOCK_NAME = 'reg_reset'
    BLOCK_TEMPLATE = "${name} <= ${width}'h0;\n"

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        s = ''
        for v in self.reg_description:
            # BRAM should not to be reseted
            if v['count'] == 0:
                d = {
                    'name': v['name'],
                    'width': v['width'] * 8
                }
                s += Template(self.BLOCK_TEMPLATE).substitute(d)

        return s

def get_bram_addr(count: int, addr):
    addr_space = math.ceil(math.log2(count))
    return f'{addr}[{addr_space + 1}:2]'

def get_bram_addr_access(count, addr):
    addr_space = math.ceil(math.log2(count))
    return (addr >> addr_space).encode('hex') + 'x' * (addr_space + 2)

class WriteBlockGen(CodeBlockGenerator):
    '''Register write block generator'''
    BLOCK_NAME = 'reg_write'
    BLOCK_TEMPLATE = "h${addr}:begin\n${write_block}end\n"
    REG_WRITE_STRB = "if(${write_strobe}[${n}])\n\t${name}[${end_bit}:${start_bit}] <= ${write_data}[${end_bit}:${start_bit}];\n"
    REG_WRITE = "${name} <= ${write_data}[${end_bit}:0];\n"
    BRAM_WRITE_STRB = "if(${write_strobe}[${n}])\n\t${name}[${addr}][${end_bit}:${start_bit}] <= ${write_data}[${end_bit}:${start_bit}];\n"
    BRAM_WRITE = "${name}[${addr}] <= ${write_data}[${end_bit}:0];\n"

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        # Signal name
        write_strobe = self.signals['write-strobe']
        write_addr = self.signals['write-addr']
        write_data = self.signals['write-data']

        for v in self.reg_description:
            block = ''

            if write_strobe == 'none':
                # Generate whole register write block
                d = {
                    'name': v['name'],
                    'end_bit': 8 * v['width'] - 1,
                    'write_data': write_data
                }

                if v['count'] == 0:
                    block = Template(self.REG_WRITE).substitute(d)
                else:
                    # Get bram write address and append
                    d['addr'] = get_bram_addr(v['count'], write_addr)

                    block = Template(self.BRAM_WRITE).substitute(d)
            else:
                # Generate byte strobe block
                strb_code = ''
                for i in range(0,v['bytes']):
                    d = {
                        'n': str(i),
                        'start_bit': i * 8,
                        'end_bit': (i + 1) * 8 - 1,
                        'write_strobe': write_strobe,
                        'write_data': write_data
                    }   

                    if v['count'] == 0:
                        # Register access
                        strb_code += Template(self.REG_WRITE_STRB).safe_substitute(d)
                    else:
                        # BRAM access
                        # Get access address and append
                        d['addr'] = get_bram_addr(v['count'], write_addr)

                        strb_code += Template(self.BRAM_WRITE_STRB).safe_substitute(d)

                block = Template(strb_code).substitute(name = v['name'])
            
            # Address generation
            if v['count'] == 0:
                # Access single register.
                addr_access = v['addr']
            else:
                # Access a BRAM.
                addr_access = get_bram_addr_access(v['count'], v['addr'])

            d = {
                'addr': addr_access,
                'write_block': block
            }

        return Template(self.BLOCK_TEMPLATE).substitute(d)

class ReadBlockGen(CodeBlockGenerator):
    '''Read block generator, base class'''
    BLOCK_NAME = 'reg_reset'
    BLOCK_TEMPLATE = "h${addr}:begin\n${read_block}end\n"
    REG_READ = ''
    BRAM_READ = ''

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        # Signals
        read_data = self.signals['read-data']

        block = ''
        for v in self.reg_description:
            # Get register/BRAM address
            if v['count'] == 0:
                # Access single register.
                d = {
                    'read_data': read_data,
                    'name': v['name']
                }
            else:
                # Access a BRAM.
                d = {
                    'read_data': read_data,
                    'ram_addr': get_bram_addr(v['count'], v['addr']),
                    'name': v['name']
                }

            block += Template(self.REG_READ).substitute(d)

            # Get register access address
            if v['count'] == 0:
                # Access single register.
                addr_access = v['addr']
            else:
                # Access a BRAM.
                addr_access = get_bram_addr_access(v['count'], v['addr'])

        d = {
            'addr': addr_access,
            'read_block': block
        }

        return Template(self.BLOCK_TEMPLATE).substitute(d)

class ReadBlockGenSync(ReadBlockGen):
    '''Read block generator, synchonous'''
    REG_READ = '${read_data} <= ${name}'
    BRAM_READ = '${read_data} <= ${name}[${ram_addr}:2]'

class ReadBlockGenAsync(ReadBlockGen):
    '''Read block generator, asynchonous'''
    REG_READ = '${read_dara} = ${name}'
    BRAM_READ = '${read_data} = ${name}[${ram_addr}:2]'

class FieldDefineGen(CodeBlockGenerator):
    '''Field define generator'''
    BLOCK_NAME = 'reg_field_define'
    BLOCK_TEMPLATE = "$wire [${width}-1:0] ${field};\n"

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        s = ''
        for w in self.reg_description:
            for v in w['fields']:
                # Width of the field
                bitRange = v['bit'].split(':')

                d = {
                    'width': int(bitRange[0]) - int(bitRange[1]),
                    'field': v['name']
                }
                
                s += Template(self.BLOCK_TEMPLATE).substitute(d)

        return s

class FieldAssignmentGen(CodeBlockGenerator):
    '''Field assignment generator'''
    BLOCK_NAME = 'reg_field_assign'
    BLOCK_TEMPLATE = "assign ${field} = ${reg}[${bit_range}];\n"

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        s = ''
        for w in self.reg_description:
            for v in w['fields']:
                if v['type'] == 0:
                    d = {
                        'field': v['name'],
                        'bit_range': v['bit'],
                        'reg': w['name']
                    }

                    s += Template(self.BLOCK_TEMPLATE).substitute(d)

        return s

class FieldUpdateGen(CodeBlockGenerator):
    '''Field update generator'''
    BLOCK_NAME = 'reg_field_update'
    BLOCK_TEMPLATE = "${reg}[${bit_range}] <= ${field};\n"

    def __init__(self, desc: dict, signals: dict):
        super().__init__(desc, signals)

    def generate(self):
        s = ''

        for w in self.reg_description:
            for v in w:
                if v['type'] == 1:
                    d = {
                        'field': v['name'],
                        'bit_range': v['bit'],
                        'reg': w['name']
                    }

                    s += Template(self.BLOCK_TEMPLATE).substitute(d)

        return s
