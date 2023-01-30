print("Start of util testing")


print_backup = print
print = function(msg)
    print_backup("    " .. msg)
end


print("Testing TableCompare")
assert(AAI_TableCompare({1,2},{1,2}), "TableCompare gave false negative for list")
assert(not AAI_TableCompare({1},{1,2}), "TableCompare gave false positive for list")
assert(AAI_TableCompare({a = 1, b = 2},{a = 1, b = 2}), "TableCompare gave false negative for table")
assert(not AAI_TableCompare({a = 1},{a = 1, b = 2}), "TableCompare gave false positive for table")


print = print_backup
print("End of util testing\n")

