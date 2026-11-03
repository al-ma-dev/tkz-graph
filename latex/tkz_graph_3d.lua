-- tkz_graph_3d.lua -- part of tkz-graph : Lua code of the option 3d
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
-- Bridge between the 3D module of tkz-elements and tkz-graph / tkz-berge
-- (prototype), read by tkz-graph-3d.tex.
--
-- The 3D module computes the projections and the hidden parts ; tkz-graph
-- draws the vertices and the edges with its styles (\Vertex[Node],
-- \Edge), so that the option lua can also compute on the graph.
--
-- Results : the projections are stored in z (\tkzGetNodes creates the
-- nodes), and lists for \foreach are defined as TeX macros :
--   \<prefix>VisibleVertices  \<prefix>HiddenVertices   {A,B,...}
--   \<prefix>VisibleEdges     \<prefix>HiddenEdges      {A/B,C/D,...}
-- The hidden lists come first in the drawing (from back to front).

graph3d = {}

local function gdef(name, list)
  tex.print("\\gdef\\" .. name .. "{" .. table.concat(list, ",") .. "}")
end

local function key(a, b)
  if a < b then return a .. "/" .. b end
  return b .. "/" .. a
end

-- depth of p (larger = nearer to the camera)
local function depth(cam, p)
  return cam:toward(p):dot(p - cam.target)
end

local function sort_by_depth(cam, list, pos)
  table.sort(list, function(x, y) return depth(cam, pos[x]) < depth(cam, pos[y]) end)
end

-- convex polyhedron P ; names[i] : name of the vertex i.
-- An edge is hidden when its two faces are hidden ; a vertex is hidden
-- when all its faces are hidden. With P.opaque == false, nothing is hidden.
function graph3d.polyhedron(cam, P, names, prefix)
  prefix = prefix or ""
  local vis = {}
  for k = 1, #P.faces do vis[k] = (P.opaque == false) or P:face_visible(k, cam) end
  local seenv, pos = {}, {}
  for k, f in ipairs(P.faces) do
    if vis[k] then for _, i in ipairs(f.idx) do seenv[i] = true end end
  end
  local vv, vh = {}, {}
  for i, p in ipairs(P.vertices) do
    z[names[i]] = cam:project(p)
    pos[names[i]] = p
    table.insert(seenv[i] and vv or vh, names[i])
  end
  sort_by_depth(cam, vv, pos); sort_by_depth(cam, vh, pos)
  local ev, eh = {}, {}
  graph3d.visible = {}
  for _, e in ipairs(P.edges) do
    local seen = false
    for _, k in ipairs(e.faces) do if vis[k] then seen = true end end
    local a, b = names[e.a], names[e.b]
    table.insert(seen and ev or eh, a .. "/" .. b)
    graph3d.visible[key(a, b)] = seen
  end
  graph3d.faces = #P.faces
  tex.print("\\gdef\\" .. prefix .. "NbFaces{" .. #P.faces .. "}")
  gdef(prefix .. "VisibleVertices", vv); gdef(prefix .. "HiddenVertices", vh)
  gdef(prefix .. "VisibleEdges", ev);    gdef(prefix .. "HiddenEdges", eh)
end

-- a path or a cycle of the last polyhedron, split into visible and hidden
-- edges : \<prefix>PathVisible, \<prefix>PathHidden
function graph3d.path(list, closed, prefix)
  prefix = prefix or ""
  local pv, ph = {}, {}
  local n = #list
  for i = 1, closed and n or n - 1 do
    local a, b = list[i], list[i % n + 1]
    local seen = graph3d.visible[key(a, b)]
    if seen == nil then error("tkz_graph_3d: " .. a .. "-" .. b .. " is not an edge", 2) end
    table.insert(seen and pv or ph, a .. "/" .. b)
  end
  gdef(prefix .. "PathVisible", pv); gdef(prefix .. "PathHidden", ph)
end

-- a graph without surface (graph3 of the 3D module : G.names, G:pos,
-- G.edges) : nothing is hidden, the vertices and the edges are sorted from
-- back to front (an edge by its midpoint). \<prefix>Vertices, \<prefix>Edges
-- (a/b/tag when the edge has a tag) ; prefix "Graph" by default (\Vertices
-- and \Edges are commands of tkz-graph)
function graph3d.graph(cam, G, prefix)
  prefix = prefix or "Graph"
  local pos, vl = {}, {}
  for _, name in ipairs(G.names) do
    pos[name] = G:pos(name)
    z[name] = cam:project(pos[name])
    vl[#vl + 1] = name
  end
  sort_by_depth(cam, vl, pos)
  local el = {}
  for _, e in ipairs(G.edges) do el[#el + 1] = e end
  table.sort(el, function(x, y)
    return depth(cam, (pos[x.a] + pos[x.b]) / 2) < depth(cam, (pos[y.a] + pos[y.b]) / 2)
  end)
  local L = {}
  for i, e in ipairs(el) do
    L[i] = e.a .. "/" .. e.b .. (e.tag and ("/" .. e.tag) or "")
  end
  gdef(prefix .. "Vertices", vl); gdef(prefix .. "Edges", L)
end

-- points on a sphere (center c) : a point is hidden when it is on the back
function graph3d.on_sphere_hidden(cam, c, p)
  return cam:toward(p):dot(p - c) < 0
end

-- vertices on a sphere (center c) : z, \<prefix>VisibleVertices and
-- \<prefix>HiddenVertices (the points on the back are hidden)
function graph3d.sphere_vertices(cam, c, names, pts, prefix)
  prefix = prefix or ""
  local vv, vh, pos = {}, {}, {}
  for i, p in ipairs(pts) do
    z[names[i]] = cam:project(p)
    pos[names[i]] = p
    table.insert(graph3d.on_sphere_hidden(cam, c, p) and vh or vv, names[i])
  end
  sort_by_depth(cam, vv, pos); sort_by_depth(cam, vh, pos)
  gdef(prefix .. "VisibleVertices", vv); gdef(prefix .. "HiddenVertices", vh)
end

-- great arc from p to q on the sphere of center c (function of t in [0, 1])
function graph3d.arc(c, p, q)
  local r = (p - c):norm()
  return function(t) return c + r * ((1 - t) * (p - c) + t * (q - c)):unit() end
end

---------------------------------------------------------------------------
-- two Platonic solids (center c, circumradius r)
---------------------------------------------------------------------------
local phi = (1 + math.sqrt(5)) / 2

-- faces of the icosahedron : the triples of vertices at mutual distance 2
function graph3d.icosahedron(c, r, opaque)
  local raw = {}
  for _, s1 in ipairs({ -1, 1 }) do
    for _, s2 in ipairs({ -1, 1 }) do
      raw[#raw + 1] = point3(0, s1, s2 * phi)
      raw[#raw + 1] = point3(s1, s2 * phi, 0)
      raw[#raw + 1] = point3(s2 * phi, 0, s1)
    end
  end
  local k = r / math.sqrt(1 + phi * phi)
  local V = {}
  for i, p in ipairs(raw) do V[i] = c + k * p end
  local F = {}
  local function adj(i, j) return math.abs((raw[i] - raw[j]):norm() - 2) < 1e-9 end
  for i = 1, 12 do for j = i + 1, 12 do for l = j + 1, 12 do
    if adj(i, j) and adj(j, l) and adj(i, l) then F[#F + 1] = { i, j, l } end
  end end end
  return polyhedron(V, F, opaque)
end

-- the dodecahedron is the dual of the icosahedron : its vertices are the
-- centers of the faces, its faces turn around the vertices of the icosahedron
function graph3d.dodecahedron(c, r, opaque)
  local I = graph3d.icosahedron(point3(0, 0, 0), 1)
  local V = {}
  for k, f in ipairs(I.faces) do V[k] = c + r * f.center:unit() end
  local F = {}
  for i, v in ipairs(I.vertices) do
    local n = v:unit()
    local a = math.abs(n.x) < 0.9 and point3(1, 0, 0) or point3(0, 1, 0)
    local e1 = a:cross(n):unit()
    local e2 = n:cross(e1)
    local L = {}
    for k, f in ipairs(I.faces) do
      for _, j in ipairs(f.idx) do
        if j == i then
          local w = f.center - v
          L[#L + 1] = { k = k, t = math.atan(w:dot(e2), w:dot(e1)) }
        end
      end
    end
    table.sort(L, function(x, y) return x.t < y.t end)
    local face = {}
    for m, e in ipairs(L) do face[m] = e.k end
    F[#F + 1] = face
  end
  return polyhedron(V, F, opaque)
end

return graph3d
