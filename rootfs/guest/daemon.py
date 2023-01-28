import time, sys, mmap
import subprocess

from flask import Flask, request
app = Flask(__name__)

import fcntl, time, struct
import redis
from concurrent.futures import ProcessPoolExecutor, ThreadPoolExecutor
# executor = ProcessPoolExecutor(max_workers=2)
executor = ThreadPoolExecutor(max_workers=2)
MEMINFO = False
ENABLE_TCPDUMP = False

# DUMPPATH = '/dev/shm/dump'
if ENABLE_TCPDUMP:
    dumpfile = open('/dev/shm/dump', 'w+')
    tcpdump_proc = subprocess.Popen(['tcpdump', '--immediate-mode', '-l', '-i', 'any'], bufsize=0, shell=True, stdout=dumpfile, stderr=dumpfile, text=True)

def function(*args):
    funcname, hostname, password, request_args = args
    r = redis.Redis(host=hostname, port=6379, db=0, password=password)
    if funcname == 'hello':
        ts = time.time()
        return [ts, ts]
    if funcname == 'allocate':
        ts1 = time.time()
        l = [1] * int(request_args['size'])
        ts2 = time.time()
        return [ts1, ts2]
    if funcname == 'image':
        import image_processing
        return image_processing.lambda_handler(request_args, {'r':r})
    if funcname == 'image_filp':
        import image_filp
        return image_filp.lambda_handler(request_args, {'r':r})
    if funcname == 'image_grayscale':
        import image_grayscale
        return image_grayscale.lambda_handler(request_args, {'r':r})
    if funcname == 'image_imgfilter':
        import image_imgfilter
        return image_imgfilter.lambda_handler(request_args, {'r':r})
    if funcname == 'image_resize':
        import image_resize
        return image_resize.lambda_handler(request_args, {'r':r})
    if funcname == 'json':
        import json_dumps_loads
        return json_dumps_loads.lambda_handler(request_args, {'r':r})
    if funcname == 'ffmpeg':
        import ffmpeg_lambda_handler
        return ffmpeg_lambda_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'chameleon':
        import chameleon_handler
        return chameleon_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'matmul':
        import matmul_lambda_handler
        return matmul_lambda_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'pyaes':
        import pyaes_lambda_handler
        return pyaes_lambda_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'compression':
        import compression_handler
        return compression_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'resnet50':
        import resnet50_handler
        return resnet50_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'pagerank':
        import pagerank_handler
        return pagerank_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'resnext50':
        import resnext50_handler
        return resnext50_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'mst':
        import mst_handler
        return mst_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'bfs':
        import bfs_handler
        return bfs_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'sleep':
        import sleep_handler
        return sleep_handler.lambda_handler(request_args)
    if funcname == 'exec':
        ts1 = time.time()
        exec(request_args['script'], globals())
        ts2 = time.time()
        return [ts1, ts2]
    if funcname == 'run':
        ts1 = time.time()
        subprocess.run(request_args['args'], shell=True, check=True)
        ts2 = time.time()
        return [ts1, ts2]
    
    # framework template
    if funcname == 'torch':
        import torch_handler
        return torch_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'numpy': # error
        import numpy_handler
        return numpy_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'pyaes':
        import pyaes_handler
        return pyaes_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'scikit-learn':
        import scikit_handler
        return scikit_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'igraph':
        import igraph_handler
        return igraph_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'torchvision':
        import torchvision_handler
        return torchvision_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'pillow':
        import pillow_handler
        return pillow_handler.lambda_handler(request_args, {'r':r})
    if funcname == 'shutil':
        import shutil_handler
        return shutil_handler.lambda_handler(request_args, {'r':r})
    # if funcname == '':
    #     import _handler
    #     return _handler.lambda_handler(request_args, {'r':r})




    raise RuntimeError('unknown function')

@app.route('/')
def hello_world():
    return 'Hello, World!'

@app.route('/invoke', methods=['POST'])
def invoke():
    funcname = request.args['function']
    redishost = request.args['redishost']
    redispasswd = request.args['redispasswd']

    starttime = time.time()
    result = function(funcname, redishost, redispasswd, request.json)
    finishtime = time.time()
    return 'read %f\nprocess %f\nwrite %f' % (result[0]-starttime, result[1]-result[0], finishtime-result[1])

@app.route('/logs')
def logs():
    ret, output = subprocess.getstatusoutput('journalctl')
    return output

@app.route('/tcpdump')
def tcpdump():
    dumpfile = open('/dev/shm/dump', 'r')
    contents = dumpfile.read()
    return contents

@app.route('/dmesg')
def dmesg():
    ret, output = subprocess.getstatusoutput('dmesg')
    return output

@app.route('/makenoise')
def syslog():
    size = 1024 * 1024 * 500
    l = [1]*size
