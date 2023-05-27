import csv

special_keys = {
    '<Backspace>'                                                : '←X',
        '<Left Ctrl><Backspace></Left Ctrl>'                     : '|←X|',
        '<UpArrow>'                                              : '↑',
        '<PageUp>'                                               : 'PG↑',
        '<RightArrow>'                                           : '→',
        '<DownArrow>'                                            : '↓',
        '<PageDown>'                                             : 'PG↓',
        '<LeftArrow>'                                            : '←',
        '<Left Ctrl><UpArrow></Left Ctrl>'                       : '|↑|',
        '<Left Ctrl><RightArrow></Left Ctrl>'                    : '|→|',
        '<Left Ctrl><DownArrow></Left Ctrl>'                     : '|↓|',
        '<Left Ctrl><LeftArrow></Left Ctrl>'                     : '|←|',
        '<Return>'                                               : '←|',
        '<PrintScreen>'                                          : 'PSC',
        '<Delete>'                                               : 'DEL',
        '<Escape>'                                               : 'ESC',
        '<Home>'                                                 : 'HME',
        '<Insert>'                                               : 'INS',
        '<End>'                                                  : 'END',
        '<F1>'                                                   : 'F1',
        '<F10>'                                                  : 'F10',
        '<F11>'                                                  : 'F11',
        '<F12>'                                                  : 'F12',
        '<F2>'                                                   : 'F2',
        '<F3>'                                                   : 'F3',
        '<F4>'                                                   : 'F4',
        '<F5>'                                                   : 'F5',
        '<F6>'                                                   : 'F6',
        '<F7>'                                                   : 'F7',
        '<F8>'                                                   : 'F8',
        '<F9>'                                                   : 'F9',
        '<Tab>'                                                  : 'TAB',
        '<CapsLock>'                                             : 'CAP',
        '<NumLock>'                                              : 'NUM',
        ' '                                                      : '_',
        '<Left Ctrl>c</Left Ctrl>'                               : '|c|',
        '<Left Ctrl>v</Left Ctrl>'                               : '|v|',
        '<Left Ctrl>x</Left Ctrl>'                               : '|x|',
        '<Left Ctrl>z</Left Ctrl>'                               : '|z|',
        '<Left Ctrl>a</Left Ctrl>'                               : '|a|',
        '<Left Ctrl>b</Left Ctrl>'                               : '|b|',
        '<Left Ctrl>f</Left Ctrl>'                               : '|f|',
        '<!--  --><Left Ctrl><LeftArrow></Left Ctrl><LeftArrow>' : '<!->'
}

def write_top_of_grids(grids_to_display):
    for grid in range(grids_to_display):
        print("┌─────────────┐", end="")

def all_possible_chords():
    keys = "OLMR"
    for i in range(len(keys)):
        for j in range(len(keys)):
            for k in range(len(keys)):
                for l in range(len(keys)):
                    keys[l] + keys[k] + keys[j] + keys[i]

def import_csv_layout(csv_path):
    no_modifier_keys_prefix = "   O "
    with open(csv_path) as csvfile:
        data=[tuple(line) for line in csv.reader(csvfile) if line[0].startswith(no_modifier_keys_prefix)]
        print(data)


