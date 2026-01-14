local fs = require("@std/fs")
local luau = require("@std/luau")
local path = require("@std/path")
local system = require("@std/system")
local test = require("@std/test")

local tmpDir = system.tmpdir()

test.suite("LuauTypeOfModuleSuite", function(suite)
	suite:case("typeofmodule_basic_test", function(assert)
		local testPath = path.join(tmpDir, "typeofmodule_test.luau")
		local testFile = fs.open(testPath, "w+")
		fs.write(testFile, [[
			local function example_string(): string
				return "example"
			end

			return {
				example_string = example_string,
			}
		]])
		fs.close(testFile)

		local typePack = luau.typeofmodule(testPath)

		if typePack.head then
			for _, typeData in typePack.head do
				print(typeData)
				print(typeof(typeData))
				print(typeData:is("table"))
				if typeData:is("table") then
					print(typeData.tag)
					local props = typeData:properties()
					for propName, propType in props do
						print(`Property: {propName} -> {propType}`)
					end
				end
			end
		end
	end)

	suite:case("resolverequire", function(assert)
		local testPath = path.join(tmpDir, "resolverequire_test.luau")
		local testFile = fs.open(testPath, "w+")

		fs.write(testFile, 'print("Hello, World!")')
		local resolvedPath = luau.resolverequire("@self", testPath)
		fs.close(testFile)

		local expected = path.format(testPath):gsub("\\", "/")
		assert.eq(resolvedPath, expected)
	end)
end)
