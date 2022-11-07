'''
    test.py
'''

from GraphicInstructions import GIBox, GIString, GIJump, GIWrite, GIChart

insts = [
    'START:',
    # Border
    GIBox(x0 = 0, y0 = 100, y1 = 200, w = 200, fg_color = 2, bg_color = 0),

    GIJump(label = 'START:')
]