#!/bin/bash

PIPE=$(mktemp -u)
mkfifo $PIPE
exec 100<>$PIPE

#
for i in $(seq 3)
do
	echo
done >&100

#
for i in $(seq 10)
do
	#read <&100
	read -u100
	#{ echo s_$(date +%Y%m%d%H%M%S) > log.$i ; sleep $(expr $RANDOM % 9 + 1); echo e_$(date +%Y%m%d%H%M%S) >> log.$i; echo >&100; } &
	{ coproc MY { echo s_$(date +%Y%m%d%H%M%S) > log.$i ; sleep $(expr $RANDOM % 9 + 1); echo e_$(date +%Y%m%d%H%M%S) >> log.$i; echo >&100; } } &> /dev/null
done

wait

exec 100>&-
exec 100<&-

<< EOF

mac@debian:~$ time /bin/bash bash_coproc.sh

real	0m13.066s
user	0m0.004s
sys	0m0.004s
mac@debian:~$ ls -1t log.*
log.10
log.9
log.6
log.7
log.8
log.5
log.2
log.4
log.1
log.3
mac@debian:~$ ls -1t log.* | xargs -I {} cat {}
s_20170915140715
e_20170915140720
s_20170915140715
e_20170915140717
s_20170915140710
e_20170915140716
s_20170915140712
e_20170915140715
s_20170915140713
e_20170915140715
s_20170915140708
e_20170915140713
s_20170915140707
e_20170915140712
s_20170915140708
e_20170915140710
s_20170915140707
e_20170915140708
s_20170915140707
e_20170915140708
mac@debian:~$ 


13

s_20170915140707 5
e_20170915140712
s_20170915140712 3
e_20170915140715
s_20170915140715 2
e_20170915140717

s_20170915140707 1
e_20170915140708
s_20170915140708 5
e_20170915140713
s_20170915140713 2
e_20170915140715
s_20170915140715 5
e_20170915140720

s_20170915140707 1
e_20170915140708
s_20170915140708 2
e_20170915140710
s_20170915140710 6
e_20170915140716

EOF

