-- ==============================================================================
-- Pandoc Lua filter for Mermaid diagram rendering
-- ==============================================================================
-- Purpose: Automatically render Mermaid code blocks to PNG images during
--          Pandoc execution for inclusion in PDF and other output formats.
--
-- Usage:   pandoc input.md -o output.pdf --lua-filter mermaid.lua
--
-- Features:
--   - Detects code blocks with class 'mermaid'
--   - Renders diagrams to PNG using mermaid-cli (mmdc)
--   - Uses hash-based filenames to avoid regeneration
--   - Transparent background by default
--   - Graceful fallback if rendering fails
--   - Output directory: build/mermaid/
--   - CI/CD support: Set MERMAID_SKIP_RENDERING=true to skip rendering
-- ==============================================================================

-- Configuration
local MERMAID_DIR = os.getenv("MERMAID_OUTPUT_DIR") or "build/mermaid"
local MMDC_BIN = os.getenv("MERMAID_CLI_BIN") or "mmdc"
local SKIP_RENDERING = os.getenv("MERMAID_SKIP_RENDERING") == "true"
local MERMAID_WIDTH      = os.getenv("MERMAID_IMAGE_WIDTH")      or "80%"
local MERMAID_MAX_HEIGHT = os.getenv("MERMAID_IMAGE_MAX_HEIGHT") or "75%"

-- Helper function to create directory if it doesn't exist
local function ensure_dir(dir)
  local dir_str = pandoc.utils.stringify(dir)
  -- Use Lua's %q format for proper shell escaping
  os.execute(string.format("mkdir -p %q", dir_str))
end

-- Helper function to compute SHA256 hash of a string
local function sha256(str)
  local cmd = string.format("echo -n %q | sha256sum | cut -d' ' -f1", str)
  local handle = io.popen(cmd)
  if not handle then
    return nil
  end
  local result = handle:read("*a")
  handle:close()
  return result:gsub("%s+", "")  -- trim whitespace
end

-- Helper function to check if file exists
local function file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  end
  return false
end

-- Helper function to render Mermaid diagram
local function render_mermaid(code, output_path)
  -- Check if rendering is disabled (for CI/CD environments)
  if SKIP_RENDERING then
    io.stderr:write("⚠️  Skipping Mermaid rendering (MERMAID_SKIP_RENDERING=true)\n")
    io.stderr:write("    Set MERMAID_SKIP_RENDERING=false to enable rendering\n")
    io.stderr:write("    See MERMAID_CI_ALTERNATIVES.md for CI/CD solutions\n")
    return false
  end
  
  -- Create temporary .mmd file
  local temp_mmd = output_path:gsub("%.png$", ".mmd")
  
  -- Write Mermaid source to temp file
  local f = io.open(temp_mmd, "w")
  if not f then
    io.stderr:write("Error: Cannot write to " .. temp_mmd .. "\n")
    return false
  end
  f:write(code)
  f:close()
  
  -- Write Puppeteer JSON config for mermaid-cli
  -- mmdc --puppeteerConfigFile expects JSON (not CJS); place next to the PNG
  local puppeteer_cfg = output_path:gsub("%.png$", "-puppeteer.json")
  local fc = io.open(puppeteer_cfg, "w")
  if fc then
    fc:write('{\n')
    fc:write('  "executablePath": "/usr/bin/chromium",\n')
    fc:write('  "args": [\n')
    fc:write('    "--no-sandbox",\n')
    fc:write('    "--disable-setuid-sandbox",\n')
    fc:write('    "--disable-dev-shm-usage",\n')
    fc:write('    "--disable-gpu",\n')
    fc:write('    "--disable-extensions",\n')
    fc:write('    "--disable-crash-reporter",\n')
    fc:write('    "--disable-breakpad"\n')
    fc:write('  ]\n')
    fc:write('}\n')
    fc:close()
  end

  -- Render using mmdc
  -- -b transparent        : transparent PNG background
  -- -s 2                  : 2x scale for better quality
  -- --puppeteerConfigFile  : pass no-sandbox flags + system Chromium path
  -- --quiet               : suppress progress output
  local cmd = string.format(
    "PUPPETEER_SKIP_DOWNLOAD=true PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium"
      .. " CHROME_PATH=/usr/bin/chromium"
      .. " %s -i %q -o %q -b transparent -s 2"
      .. " --puppeteerConfigFile %q --quiet 2>&1",
    MMDC_BIN, temp_mmd, output_path, puppeteer_cfg
  )

  local success = os.execute(cmd)

  -- Clean up temp files
  os.remove(temp_mmd)
  os.remove(puppeteer_cfg)

  return success == 0 or success == true
end

-- Main filter function
function CodeBlock(block)
  -- Check if this is a mermaid code block
  if not block.classes:includes("mermaid") then
    return nil
  end
  
  -- Get the Mermaid source code and optional caption
  local code    = block.text
  local caption = block.attributes["caption"]
  
  -- Compute hash for deterministic filename
  local hash = sha256(code)
  if not hash then
    io.stderr:write("Warning: Could not compute hash for Mermaid diagram\n")
    return block  -- fallback to original code block
  end
  
  -- Ensure output directory exists
  ensure_dir(MERMAID_DIR)
  
  -- Determine output filename
  local output_path = MERMAID_DIR .. "/" .. hash .. ".png"
  
  -- Render diagram if it doesn't exist
  if not file_exists(output_path) then
    io.stderr:write("Rendering Mermaid diagram: " .. hash .. ".png\n")
    if not render_mermaid(code, output_path) then
      io.stderr:write("Warning: Failed to render Mermaid diagram\n")
      return block  -- fallback to original code block
    end
  else
    io.stderr:write("Using cached Mermaid diagram: " .. hash .. ".png\n")
  end
  
  -- Return image element instead of code block.
  -- For LaTeX/PDF: emit raw \includegraphics with keepaspectratio so tall
  -- diagrams (e.g. sequence diagrams) are bounded by both width and height.
  -- For all other formats: use a standard pandoc Image with width attribute.
  if FORMAT == "latex" or FORMAT == "pdf" then
    local w_pct = tonumber(MERMAID_WIDTH:match("(%d+)%%"))      or 80
    local h_pct = tonumber(MERMAID_MAX_HEIGHT:match("(%d+)%%")) or 75
    local graphics = string.format(
      "\\includegraphics[width=%g\\linewidth,height=%g\\textheight,keepaspectratio]{%s}",
      w_pct / 100, h_pct / 100, output_path
    )
    local latex
    if caption then
      latex = string.format(
        "\\begin{figure}[htbp]\\centering\n%s\n\\caption{%s}\n\\end{figure}",
        graphics, caption
      )
    else
      latex = "\\begin{center}" .. graphics .. "\\end{center}"
    end
    return pandoc.RawBlock("latex", latex)
  end
  -- Non-LaTeX formats: pandoc renders a captioned Image as a figure automatically
  local cap = caption and pandoc.read(caption).blocks[1].content or {}
  return pandoc.Para({
    pandoc.Image(cap, output_path, caption or "", pandoc.Attr("", {}, {{"width", MERMAID_WIDTH}}))
  })
end

-- Return the filter
return {
  {CodeBlock = CodeBlock}
}
