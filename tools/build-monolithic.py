#!/usr/bin/env python3
"""
Build a single-file experimental version of sintaxismark.sty.

This script is intended for the experimental/grid-monolithic branch.
It reads the modular sources:

  - sintaxismark-classic.sty
  - sintaxismark_grid.lua

and writes a monolithic sintaxismark.sty that contains both the classic
implementation and the experimental grid mode, with the Lua code embedded
inside a luacode* block.

Run from the repository root:

  python3 tools/build-monolithic.py

Then test with LuaLaTeX:

  lualatex demo.tex
"""

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLASSIC = ROOT / "sintaxismark-classic.sty"
LUA = ROOT / "sintaxismark_grid.lua"
OUT = ROOT / "sintaxismark.sty"
BACKUP = ROOT / "sintaxismark-entrypoint.sty"


def read_text(path: Path) -> str:
    if not path.exists():
        raise SystemExit(f"Missing required file: {path}")
    return path.read_text(encoding="utf-8")


def strip_endinput(tex: str) -> str:
    r"""Keep only the material before the first TeX \endinput."""
    marker = "\\endinput"
    if marker in tex:
        tex = tex.split(marker, 1)[0]
    return tex.rstrip() + "\n\n"


def main() -> None:
    classic = strip_endinput(read_text(CLASSIC))
    lua = read_text(LUA).rstrip() + "\n"

    if OUT.exists() and not BACKUP.exists():
        BACKUP.write_text(OUT.read_text(encoding="utf-8"), encoding="utf-8")

    # Replace the old classic header comment when present. This is cosmetic only.
    classic = classic.replace(
        "%% sintaxismark.sty  v0.6.23 (2026-06-28)",
        "%% sintaxismark.sty  v0.7.2 experimental monolithic (2026-06-29)",
        1,
    )

    appendix = rf'''
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Experimental grid mode -- integrated monolithic block
%% LuaLaTeX only. Classic mode remains available above.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\RequirePackage{{environ}}
\RequirePackage{{pgfkeys}}
\RequirePackage{{luacode}}
\usetikzlibrary{{calc}}

\newdimen\sgrid@width
\newdimen\sgrid@yoffset
\newsavebox{{\sgrid@box}}

\newcommand*{{\sgrid@valign}}{{base}}

\pgfkeys{{/sgrid/.is family,/sgrid,
  width/.code={{\sgrid@width=#1\relax}},
  yoffset/.code={{\sgrid@yoffset=#1\relax}},
  valign/.store in=\sgrid@valign,
  base/.code={{\def\sgrid@valign{{base}}}},
  t/.code={{\def\sgrid@valign{{t}}}},
  c/.code={{\def\sgrid@valign{{c}}}},
  b/.code={{\def\sgrid@valign{{b}}}},
  width=\linewidth,
  yoffset=0pt,
  valign=base,
  .unknown/.code={{}}
}}

\ifdefined\directlua

\begin{{luacode*}}
{lua}\end{{luacode*}}

  \NewEnviron{{sintaxisgrid}}[1][width=\linewidth]{{%
    \begingroup
    \pgfkeys{{/sgrid,width=\linewidth,#1}}%
    \setbox\sgrid@box=\hbox{{%
      \directlua{{
        sintaxismark_grid.render(
          "\luaescapestring{{\unexpanded\expandafter{{\BODY}}}}",
          "\number\sgrid@width"
        )
      }}%
    }}%
    \leavevmode
    \edef\sgrid@test{{\sgrid@valign}}%
    \def\sgrid@top{{t}}%
    \def\sgrid@center{{c}}%
    \def\sgrid@bottom{{b}}%
    \ifx\sgrid@test\sgrid@top
      \raisebox{{\dimexpr\ht\sgrid@box+\sgrid@yoffset\relax}}{{\usebox{{\sgrid@box}}}}%
    \else\ifx\sgrid@test\sgrid@center
      \raisebox{{\dimexpr.5\ht\sgrid@box-.5\dp\sgrid@box+\sgrid@yoffset\relax}}{{\usebox{{\sgrid@box}}}}%
    \else\ifx\sgrid@test\sgrid@bottom
      \raisebox{{\dimexpr-\dp\sgrid@box+\sgrid@yoffset\relax}}{{\usebox{{\sgrid@box}}}}%
    \else
      \raisebox{{\sgrid@yoffset}}{{\usebox{{\sgrid@box}}}}%
    \fi\fi\fi
    \endgroup
  }}
\else
  \NewEnviron{{sintaxisgrid}}[1][width=\linewidth]{{%
    \PackageError{{sintaxismark}}{{sintaxisgrid requires LuaLaTeX}}{{Compile with LuaLaTeX to use the experimental grid mode.}}%
  }}
\fi
\makeatother

%% End of integrated grid mode.
\endinput
'''

    OUT.write_text(classic + appendix, encoding="utf-8")
    print(f"Wrote {OUT}")
    print(f"Backup entry point: {BACKUP}")
    print("Now test with: lualatex demo.tex")


if __name__ == "__main__":
    main()
