-- sintaxismark_grid.lua v0.7.0
-- Experimental grid/gloss-like renderer for sintaxismark.

sintaxismark_grid = sintaxismark_grid or {}
local SG = sintaxismark_grid

local upper_labels = { SES=true, ST=true, SEC=true, PVS=true, PVC=true, OS=true }
local under_labels = { OD=true, OI=true }
local BS = string.char(92)

local function tex_escape(s)
  s = s:gsub("%%", BS .. "%")
  s = s:gsub("&", BS .. "&")
  s = s:gsub("#", BS .. "#")
  s = s:gsub("_", BS .. "_")
  return s
end

local function is_letter(c)
  return c and c:match("[%a@]") ~= nil
end

local function skip_spaces(s, i)
  local n = #s
  while i <= n and s:sub(i,i):match("%s") do i = i + 1 end
  return i
end

local function read_command(s, i)
  local n = #s
  if s:sub(i,i) ~= BS then return nil, i end
  local j = i + 1
  while j <= n and is_letter(s:sub(j,j)) do j = j + 1 end
  if j == i + 1 then return nil, i end
  return s:sub(i+1, j-1), j
end

local function read_group(s, i)
  i = skip_spaces(s, i)
  if s:sub(i,i) ~= "{" then return nil, i end
  local depth, j = 1, i + 1
  local start = j
  while j <= #s do
    local c = s:sub(j,j)
    if c == BS then
      j = j + 2
    elseif c == "{" then
      depth = depth + 1; j = j + 1
    elseif c == "}" then
      depth = depth - 1
      if depth == 0 then return s:sub(start, j-1), j + 1 end
      j = j + 1
    else
      j = j + 1
    end
  end
  return s:sub(start), #s + 1
end

local function add_text_tokens(text, tokens)
  text = text:gsub("~", " ")
  for w in text:gmatch("%S+") do
    table.insert(tokens, w)
  end
end

local function mark_type(name, starred)
  local up = name:upper()
  if upper_labels[up] then return "span", up end
  if starred then return "box", up end
  if under_labels[up] then return "under", up end
  return "tag", up
end

local function parse_content(s, tokens, marks)
  local i, n = 1, #s
  local buffer = {}
  local function flush()
    if #buffer > 0 then
      add_text_tokens(table.concat(buffer, ""), tokens)
      buffer = {}
    end
  end
  while i <= n do
    local c = s:sub(i,i)
    if c == BS then
      local cmd, j = read_command(s, i)
      if cmd then
        if cmd == "SA" then
          flush()
          local body; body, i = read_group(s, j)
          if body then parse_content(body, tokens, marks) end
        else
          local starred = false
          j = skip_spaces(s, j)
          if s:sub(j,j) == "*" then starred = true; j = j + 1 end
          local body, after = read_group(s, j)
          if body then
            flush()
            local start = #tokens + 1
            parse_content(body, tokens, marks)
            local stop = #tokens
            if stop >= start then
              local kind, label = mark_type(cmd, starred)
              table.insert(marks, {kind=kind, label=label, start=start, stop=stop})
            end
            i = after
          else
            table.insert(buffer, s:sub(i,j-1))
            i = j
          end
        end
      else
        table.insert(buffer, c); i = i + 1
      end
    else
      table.insert(buffer, c); i = i + 1
    end
  end
  flush()
end

local function token_width(tok)
  local len = utf8.len(tok) or #tok
  local punct_discount = tok:match("^[%.,;:!?]+$") and 0.10 or 0
  return math.max(0.34, 0.205 * len + 0.18 - punct_discount)
end

local function layout_tokens(tokens, width_cm)
  local positions, lines = {}, {}
  local gap = 0.26
  local line, x = 1, 0
  lines[1] = {start=1, stop=0, width=0}
  for i,tok in ipairs(tokens) do
    local w = token_width(tok)
    local add = (x > 0 and gap or 0) + w
    if x > 0 and x + add > width_cm then
      lines[line].stop = i - 1
      lines[line].width = x
      line = line + 1
      lines[line] = {start=i, stop=0, width=0}
      x = 0
    end
    if x > 0 then x = x + gap end
    positions[i] = {line=line, left=x, right=x+w, center=x+w/2, width=w}
    x = x + w
  end
  if #tokens > 0 then
    lines[line].stop = #tokens
    lines[line].width = x
  end
  return positions, lines
end

local function range_size(m) return m.stop - m.start + 1 end

local function compute_levels(marks)
  local lower = {}
  for _,m in ipairs(marks) do
    if m.kind ~= "span" then table.insert(lower, m) end
  end
  table.sort(lower, function(a,b)
    local sa, sb = range_size(a), range_size(b)
    if sa == sb then return a.start < b.start end
    return sa < sb
  end)
  for _,m in ipairs(lower) do
    local level = 1
    for _,o in ipairs(lower) do
      if o ~= m and o.start >= m.start and o.stop <= m.stop and range_size(o) < range_size(m) then
        if (o.level or 1) + 1 > level then level = (o.level or 1) + 1 end
      end
    end
    m.level = level
  end
  local span_count = 0
  for _,m in ipairs(marks) do
    if m.kind == "span" then span_count = span_count + 1; m.level = span_count end
  end
end

local function mark_segments(m, positions, lines)
  local out = {}
  local first_line = positions[m.start].line
  local last_line = positions[m.stop].line
  for line = first_line, last_line do
    local ls, le = lines[line].start, lines[line].stop
    local a = math.max(m.start, ls)
    local b = math.min(m.stop, le)
    if a <= b then
      table.insert(out, {line=line, a=a, b=b, first=(a==m.start), last=(b==m.stop)})
    end
  end
  return out
end

local function line_max_lower_levels(marks, positions, lines)
  local maxlev = {}
  for i=1,#lines do maxlev[i] = 1 end
  for _,m in ipairs(marks) do
    if m.kind ~= "span" then
      local segs = mark_segments(m, positions, lines)
      for _,seg in ipairs(segs) do
        if (m.level or 1) > maxlev[seg.line] then maxlev[seg.line] = m.level or 1 end
      end
    end
  end
  return maxlev
end

local function fmt(...) return string.format(...) end

local function draw_mark(m, positions, lines, ybase)
  local code = {}
  local segs = mark_segments(m, positions, lines)
  for si,seg in ipairs(segs) do
    local p1, p2 = positions[seg.a], positions[seg.b]
    local x1, x2 = p1.left, p2.right
    local label = BS .. "scriptsize" .. BS .. "textsc{" .. tex_escape(m.label) .. "}"
    if m.kind == "span" then
      local y = ybase + 0.48 + 0.36 * (m.level or 1)
      local ylow = ybase + 0.25
      table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x1,y,x2,y))
      if seg.first then table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x1,ylow,x1,y)) end
      if seg.last then table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x2,ylow,x2,y)) end
      if si == 1 then table.insert(code, fmt(BS .. "node[anchor=south] at (%.3f,%.3f) {%s};", (x1+x2)/2, y+0.04, label)) end
    elseif m.kind == "box" then
      local y = ybase - 0.42 - 0.34 * (m.level or 1)
      local ytop = ybase - 0.25
      table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x1,y,x2,y))
      if seg.first then table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x1,ytop,x1,y)) end
      if seg.last then table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x2,ytop,x2,y)) end
      if si == 1 then table.insert(code, fmt(BS .. "node[anchor=north] at (%.3f,%.3f) {%s};", (x1+x2)/2, y-0.05, label)) end
    elseif m.kind == "under" then
      local y = ybase - 0.28 - 0.26 * (m.level or 1)
      table.insert(code, fmt(BS .. "draw (%.3f,%.3f) -- (%.3f,%.3f);", x1,y,x2,y))
      if si == 1 then table.insert(code, fmt(BS .. "node[anchor=north] at (%.3f,%.3f) {%s};", (x1+x2)/2, y-0.05, label)) end
    else
      local y = ybase - 0.36 - 0.28 * (m.level or 1)
      if si == 1 then table.insert(code, fmt(BS .. "node[anchor=north] at (%.3f,%.3f) {%s};", (x1+x2)/2, y, label)) end
    end
  end
  return table.concat(code, string.char(10))
end

function SG.render(body, width_sp)
  local width_cm = (tonumber(width_sp) or 0) / 65536 / 28.45274
  if width_cm <= 0 then width_cm = 12 end
  local tokens, marks = {}, {}
  parse_content(body, tokens, marks)
  if #tokens == 0 then return "" end
  compute_levels(marks)
  local positions, lines = layout_tokens(tokens, width_cm)
  local maxlower = line_max_lower_levels(marks, positions, lines)
  local ybase, linegap = {}, 1.95
  local y = 0
  for l=1,#lines do
    ybase[l] = y
    y = y - (1.35 + 0.38 * maxlower[l] + linegap)
  end
  local code = {}
  table.insert(code, BS .. "begin{tikzpicture}[x=1cm,y=1cm,baseline=(current bounding box.center),line cap=round]")
  table.insert(code, BS .. "tikzset{every node/.style={inner sep=0pt,outer sep=0pt}}")
  for i,tok in ipairs(tokens) do
    local p = positions[i]
    table.insert(code, fmt(BS .. "node[anchor=base west] at (%.3f,%.3f) {%s};", p.left, ybase[p.line], tex_escape(tok)))
  end
  for _,m in ipairs(marks) do
    if m.kind == "span" then table.insert(code, draw_mark(m, positions, lines, ybase[positions[m.start].line])) end
  end
  for _,m in ipairs(marks) do
    if m.kind ~= "span" then table.insert(code, draw_mark(m, positions, lines, ybase[positions[m.start].line])) end
  end
  table.insert(code, BS .. "end{tikzpicture}")
  tex.sprint(table.concat(code, string.char(10)))
end
