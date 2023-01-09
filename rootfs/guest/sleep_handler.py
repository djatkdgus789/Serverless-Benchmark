from time import time, sleep

def lambda_handler(event):

    second = event.get('second')
    ts1 = time()
    sleep(second)
    ts2 = time()

    return [ts1, ts2]
