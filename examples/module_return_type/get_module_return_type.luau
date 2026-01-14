local luau = require("@std/luau")

local moduleTypeString = luau.typeofmodule("examples/module_return_type/mainmodule.luau")

print("Module return type\n", moduleTypeString)

-- Output:
-- Module return type
-- {
--     _metadata: {
--         id: string,
--         key: number
--     },
--     func1: (a: number) -> (s: string) -> boolean,
--     strings: {
--         [string]: string
--     }
-- }

-- type function id(t: type): type
--     local result = types.newfunction(foo, bar, baz)
--     result:setdocumentation("this is a different comment")
--     return result
-- end

-- type functionType = typeof(
--     -- this is a doc comment
--     function() end
-- )

-- type foo = id<functionType>