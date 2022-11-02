'''
    gui_compiler.py
'''
import re, sys, getopt

RE_GETLBL = r'^(\S*)::'
RE_GETCMD = r'^([A-Z]*)\s*((\S*[\s|,]*)*)'

RE_GETBOX = r'^(\w+)[\s|,]+(\w+)[\s|,]+(\w+)[\s|,]+(\w+)[\s|,]+(C\d{2})[\s|,]+(C\d{2})[\s|,]+(\w*)[\s]*'
RE_GETSTR = r"^(\w+)[\s|,]+(\w+)[\s|,]+\'([\s|\S]*)\'[\s|,]+(C\S{4})[\s|,]+(C\S{4})"
RE_GETCHT = r'^(\d+)[\s|,]+(\d+)[\s|,]+(\d+)[\s|,]+(\d+)[\s|,]+(\d+)[\s|,]+(\d+)[\s|,]+(\d+)[\s|,]+(\d+)'
RE_GETJMP = r'^(\S*)'

HELP_INFO = '''GUI Compiler v0.5.0
Usage: gui_compiler -i <Input File> -o <Output File>'''

if __name__ == '__main__':
    # Get commandline arguments
    try:
      opts, args = getopt.getopt(sys.argv, "hvi:o:")
    except getopt.GetoptError:
        print(HELP_INFO)
        sys.exit(1)
    for opt, arg in opts:
        if opt == '-i':
            input_path = arg
        elif opt == "-o":
            output_path = arg
        elif opt == "-v":
            verbose = True
        else:
            print(HELP_INFO)
            sys.exit(1)

    # Read source code
    with open(input_path, 'r', encoding = None) as f:
        source = f.readlines()

    pc = 0
    instructions = []

    strings = ''

    labels = {}
    for i, v in enumerate(source):
        matched = re.match(RE_GETLBL ,v)
        if matched is None:     # Command or invalid syntax
            matched = re.match(RE_GETCMD, v)

            if matched is None:
                # Syntax error
                raise RuntimeError(f'{input_path}: at line {i}: Invalid syntax.')

            matched = matched.groups()
            
            inst = matched[0]
            args = matched[1]

            # Match arguments
            if inst == 'BOX':
                args = re.match(RE_GETBOX, args)
                
                if args is None:        # Check error
                    raise RuntimeError(f'{input_path}: at line {i}: Invalid arguments for command "BOX".')
                
                x0 = int(args.group(1))
                y0 = int(args.group(2))
                w = int(args.group(3))
                h = int(args.group(4))
                fg_color = int(args.group(5)[1:])
                bg_color = int(args.group(6)[1:])
                lw = int(args.group(7))

                if args.group(8) == 'T':
                    fill = 1
                else:
                    fill = 0

                word_0 = y0 | ((y0 + h) << 12) | (1 << 24) | ((0x1f & x0) << 27)
                word_1 = ((0xfe0 & x0) >> 5) | (w << 7) | (fg_color << 19) | (bg_color << 23) | (fill << 27) | (lw << 28)
                word_2 = 0

                instructions.append(word_0)
                instructions.append(word_1)
                instructions.append(word_2)

                pc += 3
            elif inst == 'PRINT':
                args = re.match(RE_GETSTR, args)
                
                if args is None:        # Check error
                    raise RuntimeError(f'{input_path}: at line {i}: Invalid arguments for command "PRINT".')
                
                x0 = int(args.group(1))
                y0 = int(args.group(2))
                s = str(args.group(3))
                fg_color = int(args.group(4)[1:])
                bg_color = int(args.group(5)[1:])
                scale = int(args.group(6)[1:])

                strings += s
                ptr = len(strings)

                word_0 = y0 | ((y0 + h) << 12) | (0 << 24) | ((0x0f & x0) << 27)
                word_1 = ((0xfe0 & x0) >> 5) | ((0xfe0 & ptr) << 7) | (fg_color << 19) | (bg_color << 23) | ((0x1f & scale) << 27)
                word_2 = 0

                instructions.append(word_0)
                instructions.append(word_1)
                instructions.append(word_2)

                pc += 3
            elif inst == 'CHART':
                args = re.match(RE_GETCHT, args)
                
                if args is None:        # Check error
                    raise RuntimeError(f'{input_path}: at line {i}: Invalid arguments for command "CHART".')
                
                x0 = int(args.group(1))
                y0 = int(args.group(2))
                nx = str(args.group(3))
                kx = int(args.group(4))
                ny = int(args.group(5))
                ky = int(args.group(6))
                color0 = int(args.group(7))
                color1 = int(args.group(8))

                word_0 = y0 | ((y0 + h) << 12) | (0 << 24) | ((0x0f & x0) << 27)
                word_1 = ((0xfe0 & x0) >> 5) | ((0x0f & nx) << 7) | ((0xff & kx) << 11) | ((0x0f & ny) << 19) | ((0xff & ky) << 23)
                word_2 = color0 | (color1 << 16)

                instructions.append(word_0)
                instructions.append(word_1)
                instructions.append(word_2)

                pc += 3
            elif inst == 'JMP':
                args = re.match(RE_GETJMP, args)
                
                if args is None:        # Check error
                    raise RuntimeError(f'{input_path}: at line {i}: Invalid arguments for command "CHART".')
                
                args = args.group(0)
                destination = int(labels[args]) & 0x00ffffff

                result = (4 << 24) | destination
                result = hex(result)[2:]

                instructions.append(result)

                pc += 1
            else:
                raise RuntimeError(f'{input_path}: at line {i}: Unknown command.')

            # Verbose info
            if(verbose):
                print(f'{i} Command: {v}, PC={pc}')
                if inst == 'JMP':
                    print(word_0)
                else:
                    print(word_0)
                    print(word_1)
                    print(word_2)
        else:       # Label
            labels[matched[0]] = pc

            if(verbose):
                print(f'Label: {matched[0]}')
