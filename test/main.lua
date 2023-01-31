-- import form parent directory
package.path = package.path .. ";../?.lua"

require "stub"

-- backup actual print and make a new print that removes wow highlights
true_print = print
print = function(msg)
    true_print(AAI_CleanItemLinkForConsole(msg))
end

require "AnaronsAutoInventory_Wrap"
require "AnaronsAutoInventory_Chat"
require "AnaronsAutoInventory_Util"

AAI_print = function(msg) print("    " .. msg) end
AAI_print_original = AAI_print

require "AnaronsAutoInventory_Core"
require "AnaronsAutoInventory_Misc"
require "AnaronsAutoInventory_Roll"
require "AnaronsAutoInventory_Tags"

---- IMPORT MOCKS ----
require "item"
require "item_mock"

---- RUN TESTS ----
require "tags"
require "util"

