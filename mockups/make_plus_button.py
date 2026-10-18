# Generates the character sheet "+" attribute point button art (style A).
# Palettes come from images/ui/CharSheet/HUD_Button_Timer_*Off00.png.
# usage: python make_plus_button.py <data dir, e.g. dist>
import sys
from PIL import Image

OUT = sys.argv[1] + '/images/ui/CharSheet/'

NORMAL = dict(K=(0,0,0), B=(120,60,0), C=(165,112,7), D=(191,153,38), E=(42,41,39), G=(95,40,0))
HOVER  = dict(K=(0,0,0), B=(148,82,3), C=(196,146,20), D=(229,195,57), E=(42,41,39), G=(113,56,6))
PRESS  = dict(K=(0,0,0), B=(196,146,20), C=(177,116,10), D=(86,37,7), E=(42,41,39), G=(148,82,3))

RAISED = ["KKKKKKKKKK",
          "KCDDDDDDCK",
          "KDCCEECCBK",
          "KDCCEECCBK",
          "KDEEEEEEBK",
          "KDEEEEEEBK",
          "KDCCEECCBK",
          "KDCCEECCBK",
          "KCBBBBBBGK",
          "KKKKKKKKKK"]

def make(rows, pal, name):
    im = Image.new('RGBA', (10, 10), (0, 0, 0, 0))
    for y, r in enumerate(rows):
        for x, c in enumerate(r):
            im.putpixel((x, y), pal[c] + (255,))
    im.resize((20, 20), Image.NEAREST).save(OUT + name)
    print(OUT + name)

make(RAISED, NORMAL, 'HUD_CharSheet_StatPlus_00.png')
make(RAISED, HOVER, 'HUD_CharSheet_StatPlusHigh_00.png')
make(RAISED, PRESS, 'HUD_CharSheet_StatPlusPress_00.png')  # bevel inverted: dark top/left
