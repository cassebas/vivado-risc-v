BEGIN {
    print "cache_config,benchmark,cycles_cold_cache,cycles_warm_cache,cycles_writeattack_cache"
}
/cache/ {
    # Number of fields must be 8
    if (NF == 8) {
        printf("%s,%s,%s,%s,0\n",$2,$4,$6,$8)
    } else if (NF == 10) {
        printf("%s,%s,%s,%s,%s\n",$2,$4,$6,$8,$10)
    } else {
        printf("WARNING: number of fields doesn't match. Line number is %s\n", NR) | "cat 1>&2"
    }
}
