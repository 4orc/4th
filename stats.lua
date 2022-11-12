#!/usr/bin/env lua
local l = require"lib"
local csv,kap,o,obj,oo = l.csv,l.kap,l.o,l.obj,l.oo
local push,rnd = l.push, l.rnd
local the = l.settings[[
stats.lua : summarize a table
(c)2022, Tim Menzies <timm@ieee.org>, BSD-2 

USAGE:   stats.lua  [OPTIONS]

OPTIONS:
  -d  --dump  on crash, print stackdump = false
  -f  --file  csv file                  = ../data/auto93.csv
  -g  --go    start-up action           = data
  -h  --help  show help                 = false]]
--------------------------------------------------------------------------------
-- ## NUM
local NUM = obj"NUM"
function NUM:new(n,s) 
  self.at, self.txt  = n or 0, s or ""
  self.n, self.mu, self.m2 = 0, 0, 0
  self.lo, self.hi = math.huge, -math.huge end

function NUM:add(x)
  if x ~= "?" then
    self.n  = self.n + 1
    local d = x - self.mu
    self.mu = self.mu + d/self.n
    self.m2 = self.m2 + d*(x - self.mu)
    self.sd = (self.m2 <0 or self.n < 2) and 0 or (self.m2/(self.n-1))^0.5 
    self.lo = math.min(x, self.lo)
    self.hi = math.max(x, self.hi) end end

function NUM:mid(x) return self.mu end
function NUM:div(x) return self.sd end 
--------------------------------------------------------------------------------
-- ## SYM
local SYM = obj"SYM"
function SYM:new(n,s)
  self.at , self.txt = n or 0, s or ""
  self.n   = 0
  self.has = {}
  self.most, self.mode = 0,nil end

function SYM:add(x) 
  if x ~= "?" then 
   self.n = self.n + 1 
   self.has[x] = 1 + (self.has[x] or 0)
   if self.has[x] > self.most then
     self.most,self.mode = self.has[x], x end end end 

function SYM:mid(x) return self.mode end
function SYM:div(x) 
  local function fun(p) return p*math.log(p,2) end
  local e=0; for _,n in pairs(self.has) do e = e - fun(n/self.n) end 
  return e end
--------------------------------------------------------------------------------------------
-- ## COLS
local COLS = obj"COLS"
function COLS:new(t)
  self.names, self.all, self.x, self.y = t,{},{},{} 
  for n,s in pairs(t) do 
    local col = push(self.all, s:find"^[A-Z]+" and NUM(n,s) or SYM(n,s))
    if not s:find"X$" then
      push(s:find"[!+-]$" and self.y or self.x, col) end end end
    
function COLS:add(row)
  for _,cols in pairs{self.x, self.y} do
    for _,col in pairs(cols) do
      col:add(row[col.at]) end end 
  return row end
--------------------------------------------------------------------------------------------
-- ## DATA
local DATA = obj"DATA"
function DATA:new(src)
  self.cols,self.rows = nil,{}
  if   type(src)=="string" 
  then csv(src,       function(row) self:add(row) end)
  else map(src or {}, function(row) self:add(row) end) end end

function DATA:add(row) 
  if self.cols then push(self.rows, self.cols:add(row)) else self.cols = COLS(row) end end

function DATA:stats(  fun,cols,places)
  local t={}
  for _,col in pairs(cols or self.cols.y) do 
    local v = getmetatable(col)[fun or "mid"](col)
    t[col.txt] = type(v)=="number" and rnd(v,places) or v end
  return t end
--------------------------------------------------------------------------------------------
-- ## Start-up
local eg={}

function eg.the() oo(the) end

function eg.data() 
  local d= DATA(the.file)
  print("y mid     :  " .. o(d:stats("mid",nil,2))) 
  print("y spread  :  " .. o(d:stats("div",nil,2))) 
  print("x mid     :  " .. o(d:stats("mid", d.cols.x,2))) 
  print("x spread  :  " .. o(d:stats("div", d.cols.x,2))) end

if l.required() then return {STATS=STATS} else l.main(the,eg) end 