# Changelog — tkz-graph

All notable changes to `tkz-graph` are listed here, most recent first.

## [2.30c] — 2026/11/02

### Added

- Options `lua` and `3d` (or `3D`), LuaLaTeX only. They read the files
  `tkz-graph-lua.tex` and `tkz-graph-3d.tex`, parts of tkz-graph (not
  packages), once, at the end of the package; tkz-berge has the same
  options. No option clash, whatever the order of tkz-graph, tkz-berge and
  tkz-elements. With pdfLaTeX the option gives an error and is ignored;
  without option nothing changes.
- Option `lua` (`tkz-graph-lua.tex` + `tkz-graph.lua`, written with
  `\directlua`, no extra package): the graph of each `tikzpicture`
  (tkz-graph and tkz-berge) is recorded, with the commands
  `\tkzGraphOrder`, `\tkzGraphSize`, `\tkzGraphDegree`, `\tkzGraphInDegree`,
  `\tkzGraphOutDegree`, `\tkzGraphDegreeSequence`, `\tkzGraphDegreeTable`;
  `\tkzGraphDijkstra` (path drawn, `\tkzGraphPath`, `\tkzGraphPathLength`,
  `\tkzGraphDijkstraTable`); `\tkzGraphColoring` (Welsh-Powell,
  `\tkzGraphColorCount`, `\tkzGraphVertexColor`, `\tkzGraphColoringTable`);
  `\tkzGraphComponents`, `\tkzGraphIfConnected`, `\tkzGraphOddVertices`,
  `\tkzGraphEulerType`, `\tkzGraphIfEulerian`, `\tkzGraphEuler` (Eulerian
  path or cycle, Hierholzer; option `numbers` writes the rank of each edge,
  style `EulerNumberStyle`; result in `\tkzGraphEulerPath`),
  `\tkzGraphMatrixPower` (M^k) and `\tkzGraphWalks`.
- Option `3d` (prototype; `tkz-graph-3d.tex` + `tkz_graph_3d.lua`): graphs in
  space with the 3D module of tkz-elements (package `tkz-elements-3d`),
  macros `\tkzGraphEdges`, `\tkzGraphVertices`, `\tkzGraphHighlight`.
- Empty hooks `\tkzgr@hook@reset`, `\tkzgr@hook@vertex`, `\tkzgr@hook@edge`
  used by the option `lua`.
- Documentation: section "Computations with LuaLaTeX".

### Fixed

- `\Edge(A)(A)` without label and arrow is no longer drawn: no more pgf
  warnings "Returning node center" with `\grComplete` (same output).
- Option `lua`: the label, arrow and style of an edge are expanded before
  being sent to Lua; a style given by `\SetUpEdge[style={...}]` gave the
  error "I do not know the key '/tikz/thick,double = ...'".
- `\Edge(A)(A)` (drawn by `\grComplete`, invisible) is no longer recorded:
  `\tkzAdjacencyMatrix` of a complete graph had 1 on the diagonal.

## [2.20c] — 2026/10/20

### Changed

- Keys use `pgfkeys` instead of `xkeyval`: same names, same default values,
  same results. The behaviour of `\presetkeys` is kept (preset values apply
  only to the keys not given; `\SetVertexMath`, `\SetUpEdge`, `\GraphInit`...
  still change them).
- `xkeyval` is no longer loaded: a document that used it without loading it
  must now load it.
- `vstyle` and the `dir` key of `\grLoop` accept a macro as value.
- The short names (`\Vertex`, `\Vertices`, `\Edge`, `\Edges`, `\Loop`, `\EA`,
  `\WE`, `\NO`, `\SO`, `\NOEA`, `\NOWE`, `\SOEA`, `\SOWE`) are installed at the
  beginning of each `tikzpicture`. A definition of `\EA`, `\NO`... made
  elsewhere (by the user or another package) keeps its meaning outside the
  pictures. If such a name is already defined when tkz-graph is loaded, a
  warning gives the prefixed name.
- The code calls only internal commands (`\tkzgr@...`); tkz-berge does the same.
- Each `vstyle` is a pgfkeys key (`/tkzgraph/vstyle/<name>`).
- Internal macros protected; `\ifthenelse` no longer used internally
  (`ifthen` is still loaded); `etex` removed; `\fileversion` and `\filedate`
  are no longer redefined.

### Fixed
- `\AddVertexColor` and `\Vertices` no longer depend on global helper macros
  (`\deb`, `\fin`, `\v`, `\liste`...).

- A second `\GraphInit[vstyle=...]` in the same group was ignored and wrote
  its value in the text (the internal macro `\GR@init@vstyle` overwrote the
  key itself).

### Added
  - Prefixed names, always available: `\tkzVertex`, `\tkzVertices`, `\tkzEdge`,
    `\tkzEdges`, `\tkzLoop`, `\tkzEA`, `\tkzWE`, `\tkzNO`, `\tkzSO`, `\tkzNOEA`,
    `\tkzNOWE`, `\tkzSOEA`, `\tkzSOWE`.
  - Package option `noshortnames`: the short names are never defined.
  - `\tkzDefGraphStyle{<name>}{<code>}` defines a new style for
    `\GraphInit[vstyle=<name>]` (name case insensitive).

  - `\tkzSetUpGraph[...]`: local settings of the vertices, edges and labels
      (`vertex shape`, `vertex line width`, `vertex line color`, `vertex text color`,
      `vertex fill`, `light fill`, `dark fill`, `ball color`, `inner sep`,
      `outer sep`, `small size`, `medium size`, `big size`, `edge color`,
      `edge width`, `edge fill`, `art color`, `double distance`, `label text`,
      `label fill`, `unit`), `directed` (an arrow on every edge) and `arrow tip`.
      It replaces the `\renewcommand` of `\VertexShape`, `\EdgeLineWidth`...
    - Keys `->`, `<-`, `<->`, `-` and `arrow` for `\Edge` and `\Edges`.
    - Keys `rotation` (angle of the first vertex) and `clockwise` for
      `\Vertices{circle}`.
    - `\tkzHighlightPath[options]{A,B,C}` (path, option `cycle`) and
      `\tkzHighlightPath{A/B,C/D}` (edges): edges drawn again over the graph
      (`color`, `lw`, `style`).
    - `\tkzAdjacencyMatrix[options]`: adjacency matrix of the graph of the last
      picture (options `directed`, `order`).
    - `\tkzGraphFromMatrix[options]{A,B,C}{0,1,1;1,0,1;1,1,0}`: graph (vertices
      on a circle, or `placed`) from a matrix; options `directed`, `weighted`,
      `unit`, `rotation`, `clockwise`, `style`, `loop distance`, `bend`.
    - `\grProbMatrix{A,B,C}{matrix}`: probabilistic graph with any number of
      states, from the transition matrix.


### Compatibility
  - Same rendering for the existing documents. `arrows.meta` is not loaded
    (it changes slightly the default tip); load it to use `arrow tip=Stealth`.

- tkz-berge must be 2.20c or later (older versions need `xkeyval`).

## [2.00] — 2021/01/20
- Correction of bugs and new documentation.

## 1.00
- First version.
