-- tkz-graph.lua -- part of tkz-graph : Lua code of the option lua
-- Copyright 2026  Alain Matthes
-- SPDX-License-Identifier: LPPL-1.3c
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3c
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   https://www.latex-project.org/lppl.txt
-- and version 1.3c or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
--
-- This work has the LPPL maintenance status "maintained".
--
-- The Current Maintainer of this work is Alain Matthes.
--
-- Read by tkz-graph-lua.tex (LuaLaTeX only). The graph of the current
-- tikzpicture is recorded by the hooks of tkz-graph (vertices, edges,
-- loops). The functions below compute and send TeX code back with
-- tex.sprint.

local tkzgraph = {}

local G          -- current graph
local last_dij   -- result of the last Dijkstra
local last_col   -- result of the last coloring

---------------------------------------------------------------------------
-- graph model
---------------------------------------------------------------------------
function tkzgraph.reset()
  G = { order = {}, index = {}, edges = {}, comma = false }
end
tkzgraph.reset()

-- TeX code is read with the catcodes of LaTeX, @ being a letter
local cct = luatexbase.registernumber("catcodetable@atletter")
local function put(s) tex.sprint(cct, s) end

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function add_vertex(name)
  name = trim(name)
  if name ~= "" and not G.index[name] then
    G.order[#G.order + 1] = name
    G.index[name] = #G.order
  end
  return name
end

function tkzgraph.vertex(name)
  add_vertex(name)
end

-- weight read in a label : 3, $3$, $0.5$, $0{,}5$, \frac{2}{3}, ...
local function weight(label)
  local s = label or ""
  s = s:gsub("%$", ""):gsub("\\[,;!: ]", ""):gsub("%s", "")
  s = s:gsub("\\mathrm", ""):gsub("\\text", "")
  local a, b = s:match("^\\[dt]?frac{?([%d%.,]+)}?{?([%d%.,]+)}?$")
  if a then
    if a:find(",") or b:find(",") then G.comma = true end
    a, b = tonumber((a:gsub(",", "."))), tonumber((b:gsub(",", ".")))
    if a and b and b ~= 0 then return a / b end
    return nil
  end
  s = s:gsub("[{}]", "")
  if s:find(",") then
    G.comma = true
    s = s:gsub(",", ".")
  end
  return tonumber(s)
end

-- arrow spec "X-Y" : forward when Y is not empty, backward when X is not
local function arrow_dir(spec)
  spec = trim(spec or "")
  if spec == "" then return 0 end
  local depth, pos = 0, nil
  for i = 1, #spec do
    local c = spec:sub(i, i)
    if c == "{" or c == "[" then depth = depth + 1
    elseif c == "}" or c == "]" then depth = depth - 1
    elseif c == "-" and depth == 0 then pos = i; break end
  end
  if not pos then return 0 end
  local l, r = trim(spec:sub(1, pos - 1)), trim(spec:sub(pos + 1))
  local f, b = r ~= "", l ~= ""
  if f and b then return 2 elseif f then return 1
  elseif b then return -1 else return 0 end
end

-- an arrow given in the style of the edge : style={->,bend left}
local function style_dir(style)
  local d = 0
  for item in (style or ""):gmatch("[^,]+") do
    item = trim(item)
    if not item:find("=") and not item:find("%s") and item:find("-") then
      local x = arrow_dir(item)
      if x ~= 0 then d = x end
    end
  end
  return d
end

-- {a,b} -> a,b : a style given with braces by \SetUpEdge[style={...}]
local function unbrace(s)
  s = trim(s or "")
  while s:sub(1, 1) == "{" and s:sub(-1) == "}" do
    local depth, ok = 0, true
    for i = 1, #s do
      local c = s:sub(i, i)
      if c == "{" then depth = depth + 1
      elseif c == "}" then
        depth = depth - 1
        if depth == 0 and i < #s then ok = false; break end
      end
    end
    if not ok then break end
    s = trim(s:sub(2, -2))
  end
  return s
end

function tkzgraph.edge(a, b, label, arrow, style)
  style = unbrace(style)
  a, b = add_vertex(a), add_vertex(b)
  local d = arrow_dir(arrow)
  if d == 0 then d = style_dir(style) end
  G.edges[#G.edges + 1] = {
    a = a, b = b, label = label, w = weight(label),
    dir = d, style = (a ~= b) and style or "" }
end

---------------------------------------------------------------------------
-- output helpers
---------------------------------------------------------------------------
local function num(x)
  if x == math.huge then return "\\infty" end
  local s
  if math.abs(x - math.floor(x + .5)) < 1e-9 then
    s = string.format("%d", math.floor(x + .5))
  else
    s = string.format("%.6g", x)
  end
  if G.comma then s = s:gsub("%.", "{,}") end
  return s
end

local function vname(v, math_mode)
  if math_mode then return "$" .. v .. "$" end
  return v
end

local function warn(msg)
  texio.write_nl("term and log",
    "Package tkz-graph Warning: " .. msg .. " on input line "
    .. tex.inputlineno .. ".")
  texio.write_nl("term and log", "")
end

---------------------------------------------------------------------------
-- order, size, degrees
---------------------------------------------------------------------------
function tkzgraph.order() put(tostring(#G.order)) end
function tkzgraph.size()  put(tostring(#G.edges)) end

-- kind : "all", "in", "out". A loop counts 2 in "all", 1 in "in"/"out".
-- An edge without arrow counts in "in" and in "out".
local function degree(v, kind)
  local n = 0
  for _, e in ipairs(G.edges) do
    if e.a == v and e.b == v then
      n = n + ((kind == "all") and 2 or 1)
    elseif e.a == v or e.b == v then
      if kind == "all" then
        n = n + 1
      else
        local out
        if e.dir == 0 or e.dir == 2 then out = true
        elseif e.dir == 1 then out = (e.a == v)
        else out = (e.b == v) end
        local inn
        if e.dir == 0 or e.dir == 2 then inn = true
        elseif e.dir == 1 then inn = (e.b == v)
        else inn = (e.a == v) end
        if (kind == "out" and out) or (kind == "in" and inn) then
          n = n + 1
        end
      end
    end
  end
  return n
end

function tkzgraph.degree(v, kind)
  v = trim(v)
  if not G.index[v] then
    warn("unknown vertex `" .. v .. "'")
    put("0")
    return
  end
  put(tostring(degree(v, kind or "all")))
end

-- vertices sorted by decreasing degree, order of creation for ties
local function by_degree()
  local t = {}
  for i, v in ipairs(G.order) do t[i] = { v = v, d = degree(v, "all"), i = i } end
  table.sort(t, function(x, y)
    if x.d ~= y.d then return x.d > y.d end
    return x.i < y.i
  end)
  return t
end

function tkzgraph.degree_sequence(sep)
  local t = by_degree()
  local out = {}
  for i, x in ipairs(t) do out[i] = tostring(x.d) end
  put(table.concat(out, sep or ", "))
end

local function tab_begin(n, first)
  put("\\begin{tabular}{" .. string.rep("c", n) .. "}\\tkzgl@top ")
  put(table.concat(first, "&") .. "\\\\\\tkzgl@mid ")
end
local function tab_end()
  put("\\tkzgl@bot\\end{tabular}")
end

function tkzgraph.degree_table(sorted, math_mode)
  local t
  if sorted then t = by_degree()
  else
    t = {}
    for i, v in ipairs(G.order) do t[i] = { v = v, d = degree(v, "all") } end
  end
  tab_begin(2, { "\\tkzGraphVertexText", "\\tkzGraphDegreeText" })
  for _, x in ipairs(t) do
    put(vname(x.v, math_mode) .. "&$" .. x.d .. "$\\\\")
  end
  tab_end()
end

---------------------------------------------------------------------------
-- Dijkstra
---------------------------------------------------------------------------
-- arcs u -> v usable ; directed : an edge without arrow goes from A to B
local function arcs(directed)
  local adj = {}
  for _, v in ipairs(G.order) do adj[v] = {} end
  for k, e in ipairs(G.edges) do
    if e.a ~= e.b then
      local w = e.w or 1
      local fw = e.dir == 1 or e.dir == 2 or (e.dir == 0)
      local bw = e.dir == -1 or e.dir == 2 or (e.dir == 0 and not directed)
      if fw then table.insert(adj[e.a], { to = e.b, w = w, k = k }) end
      if bw then table.insert(adj[e.b], { to = e.a, w = w, k = k }) end
    end
  end
  return adj
end

function tkzgraph.dijkstra(s, t, directed)
  s, t = trim(s), trim(t)
  last_dij = nil
  if not G.index[s] or not G.index[t] then
    warn("Dijkstra: unknown vertex `" .. (G.index[s] and t or s) .. "'")
    put("\\gdef\\tkzGraphPath{}\\gdef\\tkzGraphPathLength{}")
    return
  end
  for _, e in ipairs(G.edges) do
    if e.w and e.w < 0 then
      warn("Dijkstra: negative weight on the edge " .. e.a .. "-" .. e.b)
    end
  end
  local adj = arcs(directed)
  local dist, pred, pedge, done = {}, {}, {}, {}
  for _, v in ipairs(G.order) do dist[v] = math.huge end
  dist[s] = 0
  local steps = {}
  while true do
    -- snapshot of the labels before the choice
    local row = { cells = {} }
    for _, v in ipairs(G.order) do
      if done[v] then row.cells[v] = { done = true }
      else row.cells[v] = { d = dist[v], p = pred[v] } end
    end
    local best
    for _, v in ipairs(G.order) do
      if not done[v] and dist[v] < math.huge
         and (not best or dist[v] < dist[best] - 1e-12) then
        best = v
      end
    end
    row.choice = best
    steps[#steps + 1] = row
    if not best then break end
    done[best] = true
    if best == t then break end
    for _, a in ipairs(adj[best]) do
      if not done[a.to] and dist[best] + a.w < dist[a.to] - 1e-12 then
        dist[a.to] = dist[best] + a.w
        pred[a.to] = best
        pedge[a.to] = a.k
      end
    end
  end
  local path, ks = {}, {}
  if dist[t] < math.huge then
    local v = t
    while v do
      table.insert(path, 1, v)
      if pedge[v] then table.insert(ks, 1, pedge[v]) end
      v = pred[v]
    end
  else
    warn("Dijkstra: no path from " .. s .. " to " .. t)
  end
  last_dij = { s = s, t = t, steps = steps, path = path, edges = ks,
               dist = dist[t] }
  put("\\gdef\\tkzGraphPath{" .. table.concat(path, ",") .. "}")
  put("\\gdef\\tkzGraphPathLength{" ..
             (dist[t] < math.huge and num(dist[t]) or "\\infty") .. "}")
end

-- the edges of the path, each with its own style (bends are followed)
function tkzgraph.draw_path(opts)
  if not last_dij then return end
  for _, k in ipairs(last_dij.edges) do
    local e = G.edges[k]
    put("\\draw[" .. (e.style or "") .. "," .. opts .. "](" ..
               e.a .. ") to (" .. e.b .. ");")
  end
end

function tkzgraph.dijkstra_table(math_mode)
  if not last_dij then
    warn("no Dijkstra computed")
    return
  end
  local head = {}
  for i, v in ipairs(G.order) do head[i] = vname(v, math_mode) end
  head[#head + 1] = "\\tkzGraphChoiceText"
  tab_begin(#G.order + 1, head)
  for _, row in ipairs(last_dij.steps) do
    if row.choice then
      local c = {}
      for i, v in ipairs(G.order) do
        local x = row.cells[v]
        if x.done then c[i] = "\\tkzGraphDoneMark"
        elseif x.d == math.huge then c[i] = "$\\infty$"
        elseif x.p then
          c[i] = "$" .. num(x.d) .. "\\,(" .. x.p .. ")$"
        else c[i] = "$" .. num(x.d) .. "$" end
      end
      c[#c + 1] = vname(row.choice, math_mode)
      put(table.concat(c, "&") .. "\\\\")
    end
  end
  tab_end()
end

---------------------------------------------------------------------------
-- Welsh-Powell coloring
---------------------------------------------------------------------------
function tkzgraph.coloring(colors)
  local palette = {}
  for c in colors:gmatch("[^,]+") do palette[#palette + 1] = trim(c) end
  local nb = {}
  for _, v in ipairs(G.order) do nb[v] = {} end
  for _, e in ipairs(G.edges) do
    if e.a ~= e.b then nb[e.a][e.b] = true; nb[e.b][e.a] = true end
  end
  local t = by_degree()
  local color, k = {}, 0
  local left = #t
  while left > 0 do
    k = k + 1
    local class = {}
    for _, x in ipairs(t) do
      if not color[x.v] then
        local ok = true
        for _, u in ipairs(class) do
          if nb[x.v][u] then ok = false; break end
        end
        if ok then
          color[x.v] = k
          class[#class + 1] = x.v
          left = left - 1
        end
      end
    end
  end
  if k > #palette then
    warn(k .. " colors needed, " .. #palette .. " given: colors reused")
  end
  local function cname(i) return palette[(i - 1) % #palette + 1] end
  last_col = { t = t, color = color, k = k, cname = cname }
  put("\\gdef\\tkzGraphColorCount{" .. k .. "}")
end

-- vertices drawn again, one \AddVertexColor-like call per class
function tkzgraph.draw_coloring(cmd)
  if not last_col then return end
  for i = 1, last_col.k do
    local class = {}
    for _, x in ipairs(last_col.t) do
      if last_col.color[x.v] == i then class[#class + 1] = x.v end
    end
    put(cmd .. "{" .. last_col.cname(i) .. "}{" ..
               table.concat(class, ",") .. "}")
  end
end

function tkzgraph.vertex_color(v)
  v = trim(v)
  if last_col and last_col.color[v] then
    put(last_col.cname(last_col.color[v]))
  end
end

function tkzgraph.coloring_table(math_mode)
  if not last_col then
    warn("no coloring computed")
    return
  end
  tab_begin(3, { "\\tkzGraphVertexText", "\\tkzGraphDegreeText",
                 "\\tkzGraphColorText" })
  for _, x in ipairs(last_col.t) do
    local c = last_col.cname(last_col.color[x.v])
    put(vname(x.v, math_mode) .. "&$" .. x.d ..
               "$&\\tkzGraphColorSwatch{" .. c .. "}\\\\")
  end
  tab_end()
end

---------------------------------------------------------------------------
-- connectivity (the orientation of the edges is ignored)
---------------------------------------------------------------------------
local function components()
  local comp, n = {}, 0
  local nb = {}
  for _, v in ipairs(G.order) do nb[v] = {} end
  for _, e in ipairs(G.edges) do
    table.insert(nb[e.a], e.b); table.insert(nb[e.b], e.a)
  end
  for _, v in ipairs(G.order) do
    if not comp[v] then
      n = n + 1
      local stack = { v }
      comp[v] = n
      while #stack > 0 do
        local u = table.remove(stack)
        for _, w in ipairs(nb[u]) do
          if not comp[w] then comp[w] = n; stack[#stack + 1] = w end
        end
      end
    end
  end
  return n, comp
end

function tkzgraph.components() put(tostring((components()))) end

function tkzgraph.if_connected()
  put((components() <= 1) and "\\@firstoftwo" or "\\@secondoftwo")
end

---------------------------------------------------------------------------
-- Euler
---------------------------------------------------------------------------
-- directed when asked, or when every edge (loops apart) has an arrow
local function all_oriented()
  local n = 0
  for _, e in ipairs(G.edges) do
    if e.a ~= e.b then
      if e.dir == 0 then return false end
      n = n + 1
    end
  end
  return n > 0
end

-- arc of an edge in a directed graph : tail, head
local function tail_head(e)
  if e.dir == -1 then return e.b, e.a end
  return e.a, e.b
end

-- kind : "cycle", "path" or "none" ; starts : possible first vertices
local function euler_kind(directed)
  if #G.edges == 0 then return "none", {} end
  -- the edges must be in one component
  local _, comp = components()
  local c
  for _, e in ipairs(G.edges) do
    if c and comp[e.a] ~= c then return "none", {} end
    c = comp[e.a]
  end
  if directed then
    local bal = {}
    for _, v in ipairs(G.order) do bal[v] = 0 end
    for _, e in ipairs(G.edges) do
      local t, h = tail_head(e)
      bal[t] = bal[t] + 1; bal[h] = bal[h] - 1
    end
    local plus, minus, bad = {}, 0, false
    for _, v in ipairs(G.order) do
      if bal[v] == 1 then plus[#plus + 1] = v
      elseif bal[v] == -1 then minus = minus + 1
      elseif bal[v] ~= 0 then bad = true end
    end
    if bad then return "none", {} end
    if #plus == 0 and minus == 0 then return "cycle", {} end
    if #plus == 1 and minus == 1 then return "path", plus end
    return "none", {}
  else
    local odd = {}
    for _, v in ipairs(G.order) do
      if degree(v, "all") % 2 == 1 then odd[#odd + 1] = v end
    end
    if #odd == 0 then return "cycle", {} end
    if #odd == 2 then return "path", odd end
    return "none", {}
  end
end

function tkzgraph.odd_vertices(sep)
  local odd = {}
  for _, v in ipairs(G.order) do
    if degree(v, "all") % 2 == 1 then odd[#odd + 1] = v end
  end
  put(table.concat(odd, sep or ","))
end

function tkzgraph.euler_type()
  put((euler_kind(all_oriented())))
end

function tkzgraph.if_eulerian()
  local k = euler_kind(all_oriented())
  if k == "cycle" then put("\\tkzgl@firstofthree")
  elseif k == "path" then put("\\tkzgl@secondofthree")
  else put("\\tkzgl@thirdofthree") end
end

local last_euler

-- Hierholzer ; the edges are taken in their order of creation
function tkzgraph.euler(start, directed)
  start = trim(start or "")
  if not directed then directed = all_oriented() end
  last_euler = nil
  local kind, starts = euler_kind(directed)
  if kind == "none" then
    warn("Euler: the graph has no Eulerian path")
    put("\\gdef\\tkzGraphEulerPath{}")
    return
  end
  local first
  if kind == "path" then
    for _, v in ipairs(starts) do
      if v == start then first = v end
    end
    if start ~= "" and not first then
      warn("Euler: a path cannot start at " .. start)
    end
    first = first or starts[1]
  else
    if start ~= "" and G.index[start] and degree(start, "all") > 0 then
      first = start
    else
      if start ~= "" then warn("Euler: unknown or isolated vertex " .. start) end
      first = G.edges[1].a
      if directed then first = (tail_head(G.edges[1])) end
    end
  end
  -- incident edges : {edge index, other end}
  local inc = {}
  for _, v in ipairs(G.order) do inc[v] = {} end
  for k, e in ipairs(G.edges) do
    if directed then
      local t, h = tail_head(e)
      table.insert(inc[t], { k = k, to = h })
    else
      table.insert(inc[e.a], { k = k, to = e.b })
      if e.a ~= e.b then table.insert(inc[e.b], { k = k, to = e.a }) end
    end
  end
  local used, ptr = {}, {}
  for _, v in ipairs(G.order) do ptr[v] = 1 end
  local stack = { { v = first } }
  local circuit = {}
  while #stack > 0 do
    local top = stack[#stack]
    local v = top.v
    local list = inc[v]
    while ptr[v] <= #list and used[list[ptr[v]].k] do ptr[v] = ptr[v] + 1 end
    if ptr[v] <= #list then
      local a = list[ptr[v]]
      used[a.k] = true
      stack[#stack + 1] = { v = a.to, k = a.k }
    else
      table.insert(circuit, 1, table.remove(stack))
    end
  end
  local path, ks = {}, {}
  for i, x in ipairs(circuit) do
    path[i] = x.v
    if x.k then ks[#ks + 1] = x.k end
  end
  last_euler = { path = path, edges = ks, kind = kind }
  put("\\gdef\\tkzGraphEulerPath{" .. table.concat(path, ",") .. "}")
end

-- number of each edge in the path, written on the edge
function tkzgraph.draw_euler(pos)
  if not last_euler then return end
  for i, k in ipairs(last_euler.edges) do
    local e = G.edges[k]
    if e.a == e.b then
      put("\\path (" .. e.a .. ") node[EulerNumberStyle,yshift=1.2em]{"
          .. i .. "};")
    else
      put("\\path[" .. (e.style or "") .. "](" .. e.a ..
          ") to node[EulerNumberStyle,pos=" .. pos .. "]{" .. i ..
          "} (" .. e.b .. ");")
    end
  end
end

---------------------------------------------------------------------------
-- powers of the adjacency matrix, walks
---------------------------------------------------------------------------
-- same rules as \tkzAdjacencyMatrix : directed, an edge A-B counts only
-- for (A,B) ; a loop counts 1
local function adjacency(order, directed)
  local idx = {}
  for i, v in ipairs(order) do idx[v] = i end
  local n = #order
  local M = {}
  for i = 1, n do
    M[i] = {}
    for j = 1, n do M[i][j] = 0 end
  end
  for _, e in ipairs(G.edges) do
    local i, j = idx[e.a], idx[e.b]
    if i and j then
      M[i][j] = M[i][j] + 1
      if not directed and i ~= j then M[j][i] = M[j][i] + 1 end
    end
  end
  return M
end

local function power(M, k)
  local n = #M
  local R = {}
  for i = 1, n do
    R[i] = {}
    for j = 1, n do R[i][j] = (i == j) and 1 or 0 end
  end
  for _ = 1, k do
    local T = {}
    for i = 1, n do
      T[i] = {}
      for j = 1, n do
        local s = 0
        for l = 1, n do s = s + R[i][l] * M[l][j] end
        T[i][j] = s
      end
    end
    R = T
  end
  return R
end

local function get_order(list)
  list = trim(list or "")
  if list == "" then return G.order end
  local t = {}
  for v in list:gmatch("[^,]+") do t[#t + 1] = trim(v) end
  return t
end

function tkzgraph.matrix_power(k, directed, list)
  local order = get_order(list)
  local R = power(adjacency(order, directed), tonumber(k) or 1)
  local rows = {}
  for i = 1, #order do
    local r = {}
    for j = 1, #order do r[j] = string.format("%d", R[i][j]) end
    rows[i] = table.concat(r, "&")
  end
  put("\\ensuremath{\\left(\\begin{array}{" .. string.rep("c", #order) ..
      "}" .. table.concat(rows, "\\\\") .. "\\end{array}\\right)}")
end

function tkzgraph.walks(k, a, b, directed)
  a, b = trim(a), trim(b)
  local ia, ib = G.index[a], G.index[b]
  if not ia or not ib then
    warn("unknown vertex `" .. (ia and b or a) .. "'")
    put("0")
    return
  end
  local R = power(adjacency(G.order, directed), tonumber(k) or 1)
  put(string.format("%d", R[ia][ib]))
end

return tkzgraph
