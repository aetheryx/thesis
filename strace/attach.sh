bazel_pid=$(bazel info | grep server_pid | awk '{ print $2 }')

sudo strace \
  --follow-forks \
  --syscall-times=us \
  --attach $bazel_pid \
   -s 0 \
   -qqq \
   -e trace=file,read,write \
   --output-separately -o ./traces/trace.txt
