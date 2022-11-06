'''
    GraphicInstrucion.py
    Graphic instruction
'''

class InstBase():
    x0: int
    y0: int
    y1: int
    opcode: int

    inst_len: int = 3

    _word0: int
    _word1: int
    _word2: int

    data: str = None
    data_addr: int

    pseudo: bool = False

    def __init__(self, x0, y0, y1):
        self.x0 = x0
        self.y0 = y0
        self.y1 = y1

    def get(self):
        return self

    def _compile_w0(self):
        return self.y0 | (self.y1 << 12) | (self.opcode << 24) | (self.x0 << 27)

    def _compile_w1(self):
        return 0

    def _compile_w2(self):
        return 0

    def compile(self):                  # Compile to machine code
        w0_dest = self._compile_w0() & 0xffffffff
        w1_dest = self._compile_w1() & 0xffffffff
        w2_dest = self._compile_w2() & 0xffffffff

        return (w0_dest, w1_dest, w2_dest)

    def _compile_hex(self):
        return ['%08x' % v for v in self.compile()]

class GIString(InstBase):
    fg_color: int
    bg_color: int
    scale: int
    data_addr: int = None

    def __init__(self, x0, y0, y1, text, fg_color, bg_color, scale):
        self.x0 = x0
        self.y0 = y0
        self.y1 = y1

        self.data = text
        self.fg_color = fg_color
        self.bg_color = bg_color
        self.scale = scale

        self.opcode = 0
        self.inst_len = 3

        super().__init__(x0, y0, y1)

    def hint(self, inst_addr):
        return \
        f'''At {inst_addr}: STRING {self._compile_hex()}
        start = ({self.x0},{self.y0}), end_y = {self.y1},
        string address = {self.data_addr}
        front color = {self.fg_color}, back color = {self.bg_color},
        scale = {self.scale}'''

    def _compile_w1(self):
        return (self.x0 >> 5) | (self.data_addr << 7) | (self.fg_color << 19) | (self.bg_color << 23) | (self.scale < 27)

    def _compile_w2(self):
        return 0

class GIBox(InstBase):
    fg_color: int
    bg_color: int
    
    w: int

    def __init__(self, x0, y0, y1, w, fg_color, bg_color):
        self.w = w
        self.fg_color = fg_color
        self.bg_color = bg_color

        self.opcode = 1
        self.inst_len = 3

        super().__init__(x0, y0, y1)

    def hint(self, inst_addr):
        return \
        f'''At {inst_addr}: BOX {self._compile_hex()}
        start = ({self.x0},{self.y0}), end_y = {self.y1},
        Width = {self.w}
        front color = {self.fg_color}, back color = {self.bg_color}'''

    def _compile_w0(self):
        return self.y0 | (self.y1 << 12) | (self.opcode << 24) | (self.x0 << 27)

    def _compile_w1(self):
        return ((self.x0 >> 5) & 0x7F) | (self.w << 7) | (self.fg_color << 20) | (self.bg_color << 24)

class GIChart(InstBase):
    color_0: int
    color_1: int
    kx: int
    ky: int
    bx: int
    by: int
    waterfall: int
    
    def __init__(self, x0, y0, y1, kx, bx, ky, by, color_0, color_1, waterfall: bool):
        self.kx = kx
        self.ky = ky
        self.bx = bx
        self.by = by
        self.color_0 = color_0
        self.color_1 = color_1

        if waterfall:
            self.waterfall = 1
        else:
            self.waterfall = 0

        self.opcode = 2
        self.inst_len = 3

        super().__init__(x0, y0, y1)

    def hint(self, inst_addr):
        return \
        f'''At {inst_addr}: BOX {self._compile_hex()}
        start = ({self.x0},{self.y0}), end_y = {self.y1},
        x' = {self.kx}x + {self.bx}, y' = {self.ky}y + {self.by},
        color_0 = {self.color_0}, color_1 = {self.color_1}
        waterfall = {self.waterfall}'''

    def _compile_w1(self):
        return (self.x0 >> 5) | (self.bx << 7) | (self.kx << 13) | (self.by << 19) | (self.ky << 25) | (1 << self.waterfall)

    def _compile_w2(self):
        return self.color_0 | (self.color_1 << 15)

class GIJump(InstBase):
    dest_addr: int

    def __init__(self, dest_addr = 0, label = ''):
        self.dest_addr = dest_addr
        self.label = label

        self.opcode = 4
        self.inst_len = 1

    def hint(self, inst_addr):
        return \
        f'''At {inst_addr}: JUMP {self._compile_hex()}
        Label = {self.label}, destination = {self.dest_addr}'''
    
    def _compile_w0(self):
        return self.dest_addr | (self.opcode << 24)

    def compile(self):                  # Compile to machine code
        return (self._compile_w0() & 0xffffffff, 0, 0)
    
    def get(self):
        return self

class GIWrite(InstBase):
    def __init__(self):
        self.opcode = 5
        self.inst_len = 1

    def hint(self, inst_addr):
        return \
        f'''At {inst_addr}: WRITE {self._compile_hex()}'''

    def _compile_w0(self):
        return self.opcode << 24

    def compile(self):                  # Compile to machine code
        return (self._compile_w0() & 0xffffffff, 0, 0)

    def get(self):
        return self
