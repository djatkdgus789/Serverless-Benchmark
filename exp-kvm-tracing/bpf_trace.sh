#!/bin/bash

if [ -n "$1" ]
then
    echo "Parameter passed = $1"
else
    echo "No parameter passed"
    exit 100
fi

option=$1

case $option in
    brq)
        sudo bpftrace -e 'tracepoint:block:block_rq_issue /strncmp("fc_vcpu", comm, 7)==0 || comm =="main"/ {@blockrq[comm] = count(); @bsize[comm] = sum(args->bytes);}'
    ;;

    bsize) #fc block req
        sudo bpftrace -e 'tracepoint:block:block_rq_issue /strncmp("fc_vcpu", comm, 7)==0 || comm =="main"/ {@blockrqsize[comm] = sum(args->bytes)}'
        #sudo bpftrace -e 'tracepoint:block:block_rq_issue /strncmp("fc_vcpu", comm, 7)==0 || comm =="main"/ {@blockrqsize[comm] = hist(args->bytes)}'
        #sudo bpftrace -e 'tracepoint:block:block_rq_complete /strncmp("fc_vcpu", comm, 7)==0 || comm =="main"/ {@blockrqsize[comm] = sum(args->nr_sector * 4)}'

    ;;
    #vfs)
    #    sudo bpftrace -e 'kretprobe:vfs_read /strncmp("fc_vcpu", comm, 7)==0 || comm =="main"/ { @bytes = hist(retval);  }'
    #;;

    _bsize) #ALL process block
        sudo bpftrace -e 'tracepoint:block:block_rq_issue {@blockrqsize[comm] = sum(args->bytes)}'
    ;;

    pf) #fc pf
        sudo bpftrace -e 'kprobe:handle_mm_fault /strncmp("fc_vcpu", comm, 7)==0 || comm =="main" || comm=="firecracker"/ {@pf[comm] = count()}'
    ;;

    _pf) #ALL process block
        sudo bpftrace -e 'kprobe:handle_mm_fault {@pf[comm] = count()}'
    ;;

    mmu_pf)
        #sudo bpftrace -e 'kprobe:kvm_mmu_page_fault /strncmp("fc_vcpu", comm, 7)==0 || comm =="main" || comm=="firecracker"/ {@pf[comm] = count()}'
        sudo bpftrace -e 'kprobe:kvm_mmu_page_fault {@pf[comm] = count()}'
    ;;

    mpf)
    sudo bpftrace -e 'kretprobe:handle_mm_fault / (retval & 4) == 4 && (strncmp("fc_vcpu", comm, 7)==0 || comm =="main")/ {@majorpf[comm] = count()}'
    ;;

    vcpublock)
        sudo bpftrace -e 'kprobe:kvm_vcpu_block { @start[tid] = nsecs;  } kprobe:kvm_vcpu_block /@start[tid]/ {@n[comm] = count(); $delta = nsecs - @start[tid];  @dist[comm] = hist($delta); @avrg[comm] = avg($delta); delete(@start[tid]); }'
    ;;

    mpf-tl)
        sudo bpftrace -e 'BEGIN { @start = nsecs;  } kretprobe:handle_mm_fault / @start != 0 && (retval & 4) == 4 && (strncmp("fc_vcpu", comm, 7)==0 ) / { printf("%d\\n", (nsecs - @start) / 1000000);  }'
    ;;

    mmu_pftime)
        sudo bpftrace -e 'kprobe:kvm_mmu_page_fault { @start[tid] = nsecs;  } kretprobe:kvm_mmu_page_fault /@start[tid]/ {@n[comm] = count(); $delta = nsecs - @start[tid];  @dist[comm] = hist($delta); @avrg[comm] = avg($delta); delete(@start[tid]); }'
    ;;

    pftime)
        sudo bpftrace -e 'kprobe:handle_mm_fault /strncmp("fc_vcpu", comm, 7)==0/ { @start[tid] = nsecs;  } kretprobe:handle_mm_fault /@start[tid]/ {@n[comm] = count(); $delta = nsecs - @start[tid];  @dist[comm] = hist($delta); @avrg[comm] = avg($delta); delete(@start[tid]); }'
    ;;

    mpftime)
        sudo bpftrace -e 'kretprobe:handle_mm_fault /(retval & 4) == 4 && strncmp("fc_vcpu", comm, 7)==0/ { @start[tid] = nsecs;  } kretprobe:handle_mm_fault /@start[tid]/ {@n[comm] = count(); $delta = nsecs - @start[tid];  @dist[comm] = hist($delta); @avrg[comm] = avg($delta); delete(@start[tid]); }'
    ;;

esac