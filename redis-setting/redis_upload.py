import redis

r = redis.Redis(host='10.20.18.215', port=6379, db=0,password="s$l0407")
#r = redis.Redis(host='localhost', port=6379, db=0,password="s$l0407")

#r = redis.StrictRedis(host='10.20.18.215', port=6379, db=0, ssl=True, password="s$l0407")


#r.set('foo', 'bar')

import os

resource_dir = "/home/ssl/snapshot-serverless/redis-setting/resources/"
for (path, dir, files) in os.walk(resource_dir):
    for filename in files:
        ext = os.path.splitext(filename)[-1]
        with open(path+"/"+filename,'rb') as f:
            r.set(filename, f.read())
        print("%s/%s" % (path, filename))

