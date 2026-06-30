# sintaxismark

`sintaxismark` is a LaTeX package for marking syntactic constituents and grammatical functions directly over running text. It is designed for grammar handouts, classroom examples, slides, and compact linguistic analyses where a full tree would be visually excessive.

The package has two complementary modes:

1. **Classic mode**: the original TikZ-overlay system based on commands such as `\spanline`, `\openbox`, `\tagbelow`, `\SES`, `\PVS`, `\OD`, `\MI`, etc. This mode draws directly over the current line.
2. **Grid mode**: an experimental LuaLaTeX-only layout mode for longer examples. It reads a nested syntactic markup, lays the example out on a token grid, computes line breaks, and draws upper spans, lower boxes, tags, colors, arrowheads, and cut ends without diagonal lines.

Documentation status: this README and the files in `doc/` document version `v0.7.3`, including the classic mode and the experimental grid mode.

## Features

- Annotate syntax directly on running text.
- Use lower open brackets with labels via `\openbox`.
- Use upper span lines with labels via `\spanline`.
- Add floating labels above or below text via `\tagabove` and `\tagbelow`.
- Underline heads or marked items via `\synul`.
- Use predefined shortcuts for common school-grammar labels and syntactic functions, such as `\SES`, `\PVS`, `\OD`, `\OI`, `\MI`, `\NN`, and `\NV`.
- Use starred forms such as `\OD*{...}` or `\MI*{...}` to switch from a simple lower label to a lower open bracket.
- Handle nested annotations with automatic depth propagation in classic mode.
- Work inside `gb4e` examples.
- Use visual presets for teaching, printing, slides, and publication contexts.
- Use the experimental `sintaxisgrid` environment for long or multiline examples.
- Set global grid options with `\sintaxismarksetup{grid/<key>=<value>}`.
- Override grid spacing, colors, arrows, and bracket ends locally.

## Requirements

`sintaxismark` requires the following LaTeX packages:

- `tikz`, with the `calc` and `arrows.meta` libraries
- `xparse`
- `xcolor`
- `expl3`
- `varwidth`
- `environ`

The experimental grid mode and the automatic splitting commands require LuaLaTeX because their layout is computed in Lua. Under LuaLaTeX, the package also loads `luacode` for the embedded grid renderer. Classic mode works with standard LaTeX engines; Lua-only commands raise an explanatory error when another engine is used.

For numbered linguistic examples, `sintaxismark` works well with `gb4e`, but `gb4e` is not required by the package itself.

Because the classic mode uses TikZ `remember picture`, compile documents twice when using classic overlays. Grid mode itself usually does not require two passes, but compiling twice is harmless when a document mixes both modes.

## Installation

For local use, place `sintaxismark.sty` in the same directory as your `.tex` file:

```tex
\usepackage{sintaxismark}
```

You can also load one of the predefined visual schemas:

```tex
\usepackage[docencia]{sintaxismark}
\usepackage[impresion]{sintaxismark}
\usepackage[diapositivas]{sintaxismark}
\usepackage[publicacion]{sintaxismark}
```

The schema can also be changed inside the document:

```tex
\setsintaxisschema{diapositivas}
```

## Classic mode: basic usage

### Lower open brackets

```tex
\openbox{OD}{Juan compró manzanas}
```

### Upper span lines

```tex
\spanline{SES}{Juan} \spanline{PVS}{compró manzanas}
```

### Floating labels

```tex
\tagbelow{NN}{Juan}
\tagabove{ST}{Juan compró manzanas}
```

### Underlining

```tex
\synul{compró}
```

## Classic shortcuts

The package defines shortcuts for frequently used labels. Some of the most common are:

```tex
\SES{...}   % simple subject
\ST{...}    % tacit subject
\SEC{...}   % compound subject
\PVS{...}   % simple verbal predicate
\PVC{...}   % compound verbal predicate
\OS{...}    % simple sentence

\OD{...}    % direct object, lower label + underline
\OI{...}    % indirect object, lower label + underline
\MI{...}    % indirect modifier
\MD{...}    % direct modifier
\NN{...}    % nominal nucleus, lower label + underline
\NV{...}    % verbal nucleus, lower label + underline
```

Since `v0.6.19`, many shortcuts have a dual behavior:

- without star: lower floating label, usually through `\tagbelow`;
- with star: lower open bracket, through `\openbox`.

Example:

```tex
\OD{manzanas}
\OD*{manzanas}
```

## Example with `gb4e`

```tex
\documentclass{article}
\usepackage{gb4e}\noautomath
\usepackage[docencia]{sintaxismark}

\begin{document}

\begin{exe}
\ex \SES{Juan} \PVS{\NV{compró} \OD{manzanas}}.
\end{exe}

\end{document}
```

Compile twice to stabilize classic TikZ overlays.

## Long examples in classic mode

For long examples, use `\SMlinewrap{...}`:

```tex
\begin{exe}
\ex \SMlinewrap{El \MI{departamento de unos monoblocks deteriorados} quedaba en la planta baja.}
\end{exe}
```

For spans that should not be broken across lines, use the no-break variants:

```tex
\openboxNB{MI}{departamento de unos monoblocks deteriorados}
\spanlineNB{SES}{El departamento de unos monoblocks deteriorados}
```

For manually split spans across two lines, use `\breakspan{...}{...}`. The first part is rendered as a right-cut span and the second as a left-cut span.

```tex
\breakspan
  {\SES{\MI{El departamento de unos monoblocks}}}
  {\SES{\MI{quedaba en la planta baja}}}
```

## Experimental grid mode

The grid mode is intended for examples whose annotations need to cross line breaks. It avoids diagonal lines by computing a token grid and drawing each segment on the correct visual line.

Use it with the `sintaxisgrid` environment:

```tex
\begin{sintaxisgrid}[width=10cm]
\SA{
  \SES{Juan}
  \PVS{
    vio
    \OD*{
      \MD{un}
      \N{tigre}
    }
  }
}
\end{sintaxisgrid}
```

The indentation is only for readability. The same example can be written compactly:

```tex
\begin{sintaxisgrid}[width=10cm]
\SA{\SES{Juan}\PVS{vio \OD*{\MD{un}\N{tigre}}}}
\end{sintaxisgrid}
```

What matters is the bracketing with braces, not the visual indentation.

### Meaning of commands in grid mode

Inside `sintaxisgrid`, commands are interpreted structurally:

- `\SES`, `\ST`, `\SEC`, `\PVS`, `\PVC`, and `\OS` draw upper spans.
- Starred commands such as `\OD*`, `\MI*`, and `\COMP*` draw lower open boxes.
- Unstarred `\OD` and `\OI` draw lower underlined functions.
- Labels such as `\MD`, `\N`, `\NN`, and `\NV` draw lower tags.

The grid parser reads the nested markup, extracts visible tokens, infers spans, computes line breaks from `width`, and renders the result with TikZ.

### Global grid options

Grid options can be set globally with `\sintaxismarksetup`:

```tex
\sintaxismarksetup{
  grid/lower-level-gap=0.75,
  grid/lower-label-sep=0.18,
  grid/token-pad-left=0.06,
  grid/token-pad-right=0.06
}
```

Available global grid keys include:

```tex
grid/upper-y-base
grid/upper-leg
grid/upper-level-gap
grid/upper-label-sep
grid/lower-y-base
grid/lower-level-gap
grid/lower-leg-top
grid/lower-label-sep
grid/tag-y-base
grid/tag-level-gap
grid/token-gap
grid/token-pad-left
grid/token-pad-right
grid/linegap
grid/line-base
grid/line-lower-extra
```

For example, `grid/token-pad-left` and `grid/token-pad-right` move vertical bracket ends slightly away from the first and last token, leaving visual air next to words such as `un` or `sus`.

### Local grid options

The same geometry keys can be overridden locally in a single environment, without the `grid/` prefix:

```tex
\begin{sintaxisgrid}[width=10cm,lower-level-gap=0.50,token-pad-left=0.03]
...
\end{sintaxisgrid}
```

### Local options per mark

Grid mode also accepts options on individual marks:

```tex
\begin{sintaxisgrid}[width=10cm]
\SA{
  \SES[color=blue]{Juan}
  \PVS[color=black,arrow=right]{
    vio
    \OD*[color=red,no-leftend]{
      \MD[color=gray]{un}
      \N{tigre}
    }
  }
}
\end{sintaxisgrid}
```

Local mark options include:

```tex
color=red
linecolor=red
line-color=red
labelcolor=blue
label-color=blue
textcolor=blue
text-color=blue
leftend=false
rightend=false
no-leftend
no-rightend
no-ends
arrow=left
arrow=right
arrow=both
arrow=none
leftarrow
rightarrow
leftrightarrow
no-arrow
```

`color` affects the line and the label of the mark. `labelcolor` changes only the label. The token text remains unaffected unless explicitly handled by a future extension.

## Main graphical keys in classic mode

Most classic commands accept an optional key-value argument:

```tex
\openbox[color=blue,linew=1pt,boxd=4ex]{OD}{manzanas}
\spanline[color=red,liney=3ex]{SES}{Juan}
```

Common keys:

| Key | Meaning |
| --- | --- |
| `color` | annotation color |
| `linew` | line width |
| `liney` | vertical position of upper span lines |
| `linegap` | gap between text and upper vertical ends |
| `labsep` | separation between span line and label |
| `boxd` | depth of lower open brackets |
| `boxsep` | separation between lower bracket and label |
| `tagy` | vertical position of floating tags |
| `tagx` | horizontal offset of floating tags |
| `underw` | underline width |
| `labelalign` | label alignment: `left`, `center`, or `right` |
| `leftarrow`, `rightarrow` | draw arrowheads |
| `leftend`, `rightend` | show or hide vertical bracket ends |

## Documentation

The documentation sources and generated PDFs are stored in `doc/`:

- [`doc/sintaxismark-doc-en.tex`](doc/sintaxismark-doc-en.tex)
- [`doc/sintaxismark-doc-es.tex`](doc/sintaxismark-doc-es.tex)
- [`doc/sintaxismark-doc-en.pdf`](doc/sintaxismark-doc-en.pdf)
- [`doc/sintaxismark-doc-es.pdf`](doc/sintaxismark-doc-es.pdf)

Build both manuals from the repository root with:

```sh
latexmk -lualatex -outdir=doc doc/sintaxismark-doc-en.tex
latexmk -lualatex -outdir=doc doc/sintaxismark-doc-es.tex
```

## Notes

- Load `gb4e` before `sintaxismark` when using both packages.
- Compile twice when using classic TikZ overlays.
- Use LuaLaTeX for `sintaxisgrid`.
- In very long examples, prefer `sintaxisgrid`; for classic mode, use `\SMlinewrap`, `\openboxNB`, or manual splitting with `\breakspan`.

## License

`sintaxismark` is distributed under the LaTeX Project Public License, version 1.3c or later. See [`LICENSE`](LICENSE).

The LPPL maintenance status is `maintained`; the Current Maintainer is Pablo Damián Zdrojewski.

## Author and support

Copyright 2026 Pablo Damián Zdrojewski.

Source repository and issue tracker: <https://github.com/pablozd/sintaxismark>
