set benchmark_elf [lindex ${argv} 0]
set benchmark_time [lindex ${argv} 1]
puts "run-single-benchmark.tcl: downloading benchmark binary ${benchmark_elf} for running benchmark."
puts "run-single-benchmark.tcl: using a delay of ${benchmark_time} seconds after starting benchmark."
connect
targets -set -filter {name =~ "Hart #0*"}
stop
dow -clear ${benchmark_elf}
puts "run-single-benchmark.tcl: starting benchmark now."
con
# Wait a while for benchmark to properly finish execution
puts "run-single-benchmark.tcl: waiting for ${benchmark_time} seconds."
after [expr ${benchmark_time} * 1000]
