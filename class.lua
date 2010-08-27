-- Simple Lua Class system
module( ..., package.seeall )

Class = {}

function Class:subclass()
  local inst = {}
  setmetatable(inst, self)
  self.__index = self
  return inst
end

function Class:new(...)
  local inst = self:subclass( inst )
  if inst.init then inst:init(...) end
  return inst
end

_G["Class"] = Class

