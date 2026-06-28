# sintaxismark

`sintaxismark` is a LaTeX package for marking syntactic constituents and grammatical functions directly over running text. It is designed for grammar handouts, classroom examples, slides, and compact linguistic analyses where a full tree would be visually excessive.

The package draws annotations with TikZ: lower open brackets, upper span lines, floating labels, underlining, arrowheads, and nested markings.

Current version: `v0.6.21` — 2026-06-15.

## Features

- Annotate syntax directly on running text.
- Use lower open brackets with labels via `\openbox`.
- Use upper span lines with labels via `\spanline`.
- Add floating labels above or below text via `\tagabove` and `\tagbelow`.
- Underline heads or marked items via `\synul`.
- Use predefined shortcuts for common school-grammar labels and syntactic functions, such as `\SES`, `\PVS`, `\OD`, `\OI`, `\MI`, `\NN`, and `\NV`.
- Use starred forms such as `\OD*{...}` or `\MI*{...}` to switch from a simple lower label to a lower open bracket.
- Handle nested annotations with automatic depth propagation.
- Work inside `gb4e` examples.
- Use visual presets for teaching, printing, slides, and publication contexts.

## Requirements

`sintaxismark` requires the following LaTeX packages:

- `tikz`, with the `calc` and `arrows.meta` libraries
- `xparse`
- `xcolor`
- `expl3`
- `varwidth`

For numbered linguistic examples, it works well with `gb4e`, but `gb4e` is not required by the package itself.

Because the package uses TikZ `remember picture`, compile your document twice.

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

## Basic usage

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

## Shortcuts

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

Compile twice to stabilize the TikZ overlays.

## Long examples and line wrapping

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

## Main graphical keys

Most commands accept an optional key-value argument:

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

The English documentation is in [`sintaxismark-doc-en.tex`](sintaxismark-doc-en.tex).

A Spanish documentation file may also be kept in the repository if desired.

## Notes

- Load `gb4e` before `sintaxismark` when using both packages.
- Compile twice because TikZ overlays rely on remembered positions.
- In very long examples, prefer `\SMlinewrap`, `\openboxNB`, or manual splitting with `\breakspan`.

## License

Add a `LICENSE` file before publishing or distributing the package formally.
