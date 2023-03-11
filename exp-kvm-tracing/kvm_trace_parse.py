from parse import *

start_time = 0
end_time = 0
pf_time = 0
cpu = [] 

# timestamp in <secs>.<usecs> format
#f = open("./recognition_ssd.trace", 'r')
#f = open("./recognition_nvme.trace", 'r')

#f = open("./recognition_dcpm.trace", 'r')
while True:
    line = f.readline()
    if not line: break

    if 'restart' in line:
        # fc_vcpu 0-552219  [040] .... 97836.519114: kvm_userspace_exit: reason restart (4)
        if start_time == 0:
            result = parse("       fc_vcpu {no}-{} [{}] {} {sec}.{micro}: kvm_userspace_exit: {}", line)
            start_time = int(result['sec']) * 1000000 + int(result['micro'])
        elif end_time == 0:
            result = parse("       fc_vcpu {no}-{} [{}] {} {sec}.{micro}: kvm_userspace_exit: {}", line)
            end_time = int(result['sec']) * 1000000 + int(result['micro'])
            

    if 'fc_vcpu 0' in line:
        if 'kvm_entry' in line:
            #fc_vcpu 0-2779478 [077] d... 1820822.383974: kvm_entry: vcpu 0
            result = parse("       fc_vcpu {no}-{} [{}] {} {sec}.{micro}: kvm_entry: {}", line)
            cpu_active = {'start': int(result['sec']) * 1000000 + int(result['micro']), 'end': 0, 'reason':''}
            cpu.append(cpu_active)


        if 'kvm_exit' in line:
            #fc_vcpu 0-2779478 [077] .... 1820822.383989: kvm_exit: vcpu 0 reason EPT_VIOLATION rip 0x5a1b20 info 384 0
            result = parse("       fc_vcpu {no}-{} [{}] {} {sec}.{micro}: kvm_exit: {} reason {reason} rip {}", line)
            # if result['reason'] == 'EPT_VIOLATION':
            reason = result['reason']
            if cpu[-1]['end'] == 0:
                cpu[-1]['reason'] = reason
                cpu[-1]['end'] = int(result['sec']) * 1000000 + int(result['micro'])
            else:
                print("vcpu exit가 더 빠름")

f.close()

for cpu_active in cpu:
    cpu_active['start'] = (cpu_active['start'] - start_time)
    cpu_active['end'] = (cpu_active['end'] - start_time)

print(cpu)
