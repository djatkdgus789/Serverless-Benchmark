import csv

f = open('./output.csv','r', encoding='utf-8')
trace_f = open('./func.trace','wt')
rdr = csv.reader(f)
s = 0
for line in rdr:
    if line[0] == " RA":
        if line[1] == 'D':
            trace_f.write(line[2])
            trace_f.write(" ")
            trace_f.write(line[3])
            trace_f.write(" ")
            trace_f.write(line[4])
            trace_f.write(" ")
            trace_f.write(line[5])
            trace_f.write(" ")
            trace_f.write(line[6])
            trace_f.write("\n")
            print("OK")
            s += int(line[5])
print(s/1024/1024)

f.close()
trace_f.close()
