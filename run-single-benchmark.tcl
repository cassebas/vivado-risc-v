set benchmark_elf [lindex ${argv} 0]
set benchmark_time [lindex ${argv} 1]
puts "Downloading benchmark binary ${benchmark_elf} for running benchmark."
puts "Using a delay of ${benchmark_time} seconds after starting benchmark."
connect
targets -set -filter {name =~ "Hart #0*"}
stop
dow -clear ${benchmark_elf}
con
# Wait a while for benchmark to properly finish execution
after [expr ${benchmark_time} * 1000]
