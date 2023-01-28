from parse import *

pf_time = 0
cpu_active = 0
cpu_sleep = 0
start = 0
finish = 1
reason = ""

f = open("./kvm.trace", 'r')
while True:
    line = f.readline()
    if not line: break

    if 'fc_vcpu 0' in line:
        if 'kvm_entry' in line and finish == 0:
            #fc_vcpu 0-2779478 [077] d... 1820822.383974: kvm_entry: vcpu 0
            result = parse("       fc_vcpu {}-{} [{}] {} {sec}.{micro}: kvm_entry: {}", line)
            if finish == 0:
                finish = int(result['sec']) * 1000000 + int(result['micro'])
                elasped_time = (finish - start)
                if elasped_time < 0:
                    print("elasped_time: {}".format(elasped_time))
                    print("finish: {}".format(finish))
                    print("start: {}".format(start))
                    print(line)


                else :
                    cpu_sleep += elasped_time

            else:
                print("Error")

        if 'kvm_exit' in line:
            #fc_vcpu 0-2779478 [077] .... 1820822.383989: kvm_exit: vcpu 0 reason EPT_VIOLATION rip 0x5a1b20 info 384 0
            result = parse("       fc_vcpu {}-{} [{}] {} {sec}.{micro}: kvm_exit: {} reason {reason} rip {}", line)
            # if result['reason'] == 'EPT_VIOLATION':
            #     start = int(result['sec']) * 1000000 + int(result['micro'])
            #     finish = 0
            reason = result['reason']
            start = int(result['sec']) * 1000000 + int(result['micro'])
            finish = 0
            


        if 'kvm_vcpu_wakeup' in line:
            #fc_vcpu 0-2779478 [076] .... 1820822.384342: kvm_vcpu_wakeup: wait time 91252 ns, polling valid
            result = parse("       fc_vcpu {}-{} [{}] {} {}.{}: {kvm_state}: {} time {kvm_vcpu_wakeup} ns, {}", line)
            #print(line)
            sleep = result['kvm_vcpu_wakeup']
            pf_time += int(sleep)

f.close()

print("CPU active time: {}us".format(cpu_active))
print("CPU active time: {}ms".format(cpu_active * 0.001))
# print("CPU sleep time: {}us".format(cpu_sleep* 100))
# print("CPU sleep time: {}ms".format(cpu_sleep * 0.001 * 100))

print("CPU sleep time: {}us".format(cpu_sleep))
print("CPU sleep time: {}ms".format(cpu_sleep * 0.001))


print("kvm_vcpu_wakeup time: {}us".format(pf_time * 0.001))
print("kvm_vcpu_wakeup time: {}ms".format(pf_time * 0.001 * 0.001))