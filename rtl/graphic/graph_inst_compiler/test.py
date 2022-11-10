'''
    test.py
'''

from GraphicInstructions import GIBox, GIString, GIJump, GIWrite, GIChart

insts = [
    'START:',
    # Border
    GIBox(x0 = 0, y0 = 0, y1 = 768, w = 128, fg_color = 3, bg_color = 0),
    GIBox(x0 = 128, y0 = 0, y1 = 768, w = 128, fg_color = 1, bg_color = 0),
    GIBox(x0 = 256, y0 = 0, y1 = 768, w = 128, fg_color = 2, bg_color = 0),
    GIBox(x0 = 384, y0 = 0, y1 = 768, w = 128, fg_color = 0, bg_color = 0),
    GIBox(x0 = 512, y0 = 0, y1 = 768, w = 128, fg_color = 0, bg_color = 0),
    GIBox(x0 = 640, y0 = 0, y1 = 768, w = 128, fg_color = 2, bg_color = 0),
    GIBox(x0 = 768, y0 = 0, y1 = 768, w = 128, fg_color = 1, bg_color = 0),
    GIBox(x0 = 896, y0 = 0, y1 = 768, w = 128, fg_color = 0, bg_color = 0),

    GIJump(label = 'START:')
]