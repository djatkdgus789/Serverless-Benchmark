import datetime, json, os, uuid
from time import time
from PIL import Image
import torch
from torchvision import transforms
from torchvision.models import resnext50_32x4d

tmp = '/dev/shm/'

SCRIPT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__)))
#class_idx = json.load(open(os.path.join(SCRIPT_DIR, "imagenet_class_index.json"), 'r'))
#idx2label = [class_idx[str(k)][1] for k in range(len(class_idx))]
model = None

def lambda_handler(event, ctx):
    r = ctx['r']

    ts1 = time()

    x = torch.rand(2, 3)

    print(x)

    ts2 = time()

    return [ts1, ts2]
