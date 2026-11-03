# tkz-graph — for graph theory

Release 2.30c 2026/11/02

## Description

The package tkz-graph.sty is a collection of some useful macros if you want to
 draw manually a graph of the graph theory. The kind of graphs that I will
  present, are sometimes called combinatorial graphs to distinguish them from
  the graphs of functions. The macros are designed to give math
 teachers (and students) easy access at the programmation of drawing graphs
  with  TikZ.  I therefore hope that my  packages provide  ideal tools for
   teachers wanting to offer their students fine documents of maths.

With LuaLaTeX, two options go further (they are optional: without them the
package is unchanged and works with pdfLaTeX):

- `lua`: computations on the graph drawn in each `tikzpicture` (tkz-graph
  and tkz-berge graphs): order, size, degrees, shortest path (Dijkstra, with
  the table of the steps), coloring (Welsh-Powell), connectivity, Eulerian
  paths and cycles, powers of the adjacency matrix. The results can be
  drawn (path, colors) or written in the text.
- `3d` (prototype): graphs in space. The 3D module of tkz-elements computes
  the projections and the hidden parts (polyhedra, sphere, hypercube...),
  tkz-graph draws the vertices and the edges with its styles. The option
  `3d` includes the option `lua`.

## License

This work may be distributed and/or modified under the conditions of the
[LaTeX Project Public License](https://www.latex-project.org/lppl/), version 1.3c
or (at your option) any later version. See the files `LICENSE` and `lppl-1-3c.txt`.

This work has the LPPL maintenance status "maintained".
The Current Maintainer of this work is Alain Matthes.

## Requirements

The package compiles with utf8, pdflatex and lualatex, loads and depends on updated versions of:
- [tikz](https://ctan.org/pkg/tikz)

Since version 2.20c, `xkeyval` is no longer needed: the keys use `pgfkeys`,
which is part of TikZ.

The options `lua` and `3d` need LuaLaTeX (with pdfLaTeX they give an error
and are ignored). The option `3d` also needs
[tkz-elements](https://ctan.org/pkg/tkz-elements) 6.10c (2026/11/01) or later.

## Installation

The package `tkz-graph` is present in TeXLive and MiKTeX, use the package
manager to install.

You can experiment with the `tkz-graph` package by placing all of the
distribution files in the directory containing your current tex file.


## How to use it

To use the package `tkz-graph`, place the following line in the preamble of
your LaTeX document:

```
\usepackage{tkz-graph}
```

With LuaLaTeX:

```
\usepackage[lua]{tkz-graph}   % computations on the graphs
\usepackage[3d]{tkz-graph}    % graphs in space (and computations)
```

The order of `tkz-graph`, `tkz-berge` and `tkz-elements` in the preamble
does not matter.

## Documentation

Documentation for `tkz-graph` is available on `CTAN`.

## Examples

All  examples given in documentation will be stored on `CTAN` as standalone
files, ready for compilation.

Other examples, in french, are on my site: [http://altermundus.fr](http://altermundus.fr)

## History

- 2.2 (2026/10/07) keys with `pgfkeys` instead of `xkeyval`, short names
  installed only in the pictures, prefixed names (`\tkzVertex`...), option
  `noshortnames`, new styles with `\tkzDefGraphStyle`.
- 2.30c (2026/11/02) options `lua` (computations on the graphs) and `3d`
  (graphs in space with tkz-elements), LuaLaTeX only.

The full list of changes is in [CHANGELOG.md](CHANGELOG.md).

## Author

Alain Matthes, 5 rue de Valence, Paris 75005, al (dot) ma (at) mac (dot) com
