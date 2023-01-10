import datetime, json, os, uuid
from time import time
import PIL

tmp = '/dev/shm/'

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__)))
#class_idx = json.load(open(os.path.join(SCRIPT_DIR, "imagenet_class_index.json"), 'r'))
#idx2label = [class_idx[str(k)][1] for k in range(len(class_idx))]
model = None

def lambda_handler(event, ctx):
    r = ctx['r']

    ts1 = time()
    
    print(PIL.__version__)

    print(x)

    ts2 = time()

    return [ts1, ts2]
