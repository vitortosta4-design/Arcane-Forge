import sys
from PIL import Image
pref=sys.argv[1]
ordem=["fogo","agua","vida","feroz","gravitacao","prende","arremesso","quebrar"]
W,H=670,460
out=Image.new('RGB',(W*2,H*8))
for i,n in enumerate(ordem):
    a=Image.open(f'/home/claude/piloto/referencias/runas_recortes/{n}.png').resize((W,H))
    b=Image.open(f'/home/claude/piloto/renders/runas2/{pref}_{n}.png').convert('RGBA')
    fundo=Image.new('RGBA',(W,H),(107,106,110,255)); fundo.alpha_composite(b)
    out.paste(a,(0,i*H)); out.paste(fundo.convert('RGB'),(W,i*H))
out.crop((0,0,W*2,H*4)).resize((W,H*2)).save(f'/home/claude/piloto/renders/runas2/{pref}_lado_1a4.png')
out.crop((0,H*4,W*2,H*8)).resize((W,H*2)).save(f'/home/claude/piloto/renders/runas2/{pref}_lado_5a8.png')
