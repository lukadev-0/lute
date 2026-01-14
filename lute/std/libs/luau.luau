--!strict
-- @std/luau
-- stdlib for `@lute/luau`
-- Provides utilities for parsing and compiling Luau source code

local luteLuau = require("@lute/luau")

local fs = require("@lute/fs")
local path = require("@std/path")

local luau = {}

export type bytecode = luteLuau.Bytecode
export type TypePack = luteLuau.TypePack

function luau.compile(source: string): bytecode
	return luteLuau.compile(source)
end

function luau.load(bytecode: bytecode, chunkname: string?, env: { [any]: any }?): (...any) -> ...any
	return luteLuau.load(bytecode, if chunkname ~= nil then `@{chunkname}` else "=luau.load", env)
end

function luau.loadbypath(requirePath: path.pathlike, env: { [any]: any }?): any
	local requirePathStr = if typeof(requirePath) == "string" then requirePath else path.format(requirePath)

	local migrationHandle = fs.open(requirePathStr, "r")

	local migrationBytecode = luau.compile(fs.read(migrationHandle))

	fs.close(migrationHandle)

	return luau.load(migrationBytecode, requirePathStr, env)()
end

function luau.typeofmodule(modulepath: path.pathlike): TypePack
	local modulePathStr = if typeof(modulepath) == "string" then modulepath else path.format(modulepath)

	return luteLuau.typeofmodule(modulePathStr)
end

function luau.resolverequire(modulepath: string, frompath: path.pathlike): string
	local frompathString = if typeof(frompath) == "string" then frompath else path.format(frompath)
	return luteLuau.resolverequire(modulepath, `@{frompathString}`)
end

-- Helper function to format a type userdata to a string representation
local function formatType(typeUserdata: any, indent: number?, visited: {[any]: boolean}?): string
	print("typeuserdata:", typeUserdata.tag)
	print("name is: ", typeUserdata.name)
	print(typeUserdata:is("table"))
	local indentLevel = indent or 0
	local indentStr = string.rep("  ", indentLevel)
	local visitedSet = visited or {}
	
	-- Prevent infinite recursion on circular references
	if visitedSet[typeUserdata] then
		return "<circular>"
	end
	visitedSet[typeUserdata] = true
	
	-- Prevent stack overflow from deep nesting
	if indentLevel > 10 then
		return "<max depth>"
	end
	
	print("before tag stuff")
	local tag = typeUserdata.tag
	print(tag)
	
	if tag == "nil" or tag == "boolean" or tag == "number" or tag == "string" or tag == "thread" or tag == "buffer" then
		return tag
	elseif typeUserdata:is("singleton") then
		local value = typeUserdata:value()
		if type(value) == "string" then
			return `"{value}"`
		else
			return tostring(value)
		end
	elseif tag == "table" then
		print("tableeeee")
		local props = typeUserdata:properties()
		print("after getting properties)")
		if not props then
			return "{}"
		end
		
		local propStrings: { string } = {}
		for propNameType, propValue in props do
			if propNameType:is("singleton") then
				local propName = propNameType:value()
				local propStr = propName .. ": "
				
				if propValue.read then
					propStr = propStr .. formatType(propValue.read, indentLevel + 1, visitedSet)
				elseif propValue.write then
					propStr = propStr .. formatType(propValue.write, indentLevel + 1, visitedSet)
				else
					propStr = propStr .. "unknown"
				end
				
				table.insert(propStrings, indentStr .. "  " .. propStr)
			end
		end
		
		if #propStrings == 0 then
			return "{}"
		end
		
		return "{\n" .. table.concat(propStrings, ",\n") .. "\n" .. indentStr .. "}"
	elseif tag == "function" then
		-- Similar changes for function...
		local params = typeUserdata:parameters()
		local returns = typeUserdata:returns()
		
		local paramStr = "()"
		if params and params.head and #params.head > 0 then
			local paramTypes: { string } = {}
			for _, paramType in params.head do
				table.insert(paramTypes, formatType(paramType, indentLevel, visitedSet))
			end
			paramStr = "(" .. table.concat(paramTypes, ", ") .. ")"
		end
		
		local returnStr = ""
		if returns and returns.head and #returns.head > 0 then
			local returnTypes: { string } = {}
			for _, returnType in returns.head do
				table.insert(returnTypes, formatType(returnType, indentLevel, visitedSet))
			end
			returnStr = " -> " .. table.concat(returnTypes, ", ")
		end
		
		return paramStr .. returnStr
	else
		return tag
	end
end

-- Format a TypePack into an API-style documentation string
function luau.formattypepack(typePack: TypePack, indent: number?): string
	print("hi")
	local indentLevel = indent or 0
	
	local parts: { string } = {}

	print(#typePack.head)
	
	if typePack.head then
		for i, typeData in typePack.head do
			print("typedata section")
			print(i, typeData)
			table.insert(parts, formatType(typeData, indentLevel))
		end
	end
	
	if typePack.tail then
		table.insert(parts, "..." .. formatType(typePack.tail, indentLevel))
	end
	
	if #parts == 0 then
		return "()"
	end
	
	return table.concat(parts, ", ")
end

return table.freeze(luau)
