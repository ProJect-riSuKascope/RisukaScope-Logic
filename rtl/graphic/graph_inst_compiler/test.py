'''
    test.py
'''

from GraphicInstructions import GIBox, GIString, GIJump, GIWrite, GIChart

insts = [
    'START:',
    GIBox(x0 = 10, y0 = 310, y1 = 230, w = 220, fg_color = 0, bg_color = 1),
    GIBox(x0 = 150, y0 = 150, y1 = 200, w = 100, fg_color = 3, bg_color = 4),
    GIWrite(),
    GIJump(label = 'START:')
]