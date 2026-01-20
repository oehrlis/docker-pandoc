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
-- ==============================================================================

local system = require('pandoc.system')

-- Configuration
local MERMAID_DIR = "build/mermaid"
local MMDC_BIN = "mmdc"

-- Helper function to create directory if it doesn't exist
local function ensure_dir(dir)
  os.execute("mkdir -p " .. pandoc.utils.stringify(dir))
end

-- Helper function to create Puppeteer config if needed
local function ensure_puppeteer_config()
  local config_dir = "build/mermaid/.puppeteer"
  local config_file = config_dir .. "/config.json"
  
  -- Check if config already exists
  local f = io.open(config_file, "r")
  if f then
    f:close()
    return config_file
  end
  
  -- Create config directory
  os.execute("mkdir -p " .. config_dir)
  
  -- Create minimal config
  local config = io.open(config_file, "w")
  if config then
    config:write('{\n')
    config:write('  "args": [\n')
    config:write('    "--no-sandbox",\n')
    config:write('    "--disable-setuid-sandbox",\n')
    config:write('    "--disable-dev-shm-usage"\n')
    config:write('  ]\n')
    config:write('}\n')
    config:close()
  end
  
  return config_file
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
  
  -- Ensure Puppeteer config exists
  local puppeteer_config = ensure_puppeteer_config()
  
  -- Render using mmdc
  -- Use --quiet to reduce output noise
  -- Use -b transparent for transparent background
  -- Use -s 2 for 2x scale (better quality)
  -- Set puppeteer config path
  local cmd = string.format(
    "PUPPETEER_CONFIG_PATH=%q %s -i %q -o %q -b transparent -s 2 --quiet 2>&1",
    puppeteer_config, MMDC_BIN, temp_mmd, output_path
  )
  
  local success = os.execute(cmd)
  
  -- Clean up temp file
  os.remove(temp_mmd)
  
  return success == 0 or success == true
end

-- Main filter function
function CodeBlock(block)
  -- Check if this is a mermaid code block
  if not block.classes:includes("mermaid") then
    return nil
  end
  
  -- Get the Mermaid source code
  local code = block.text
  
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
  
  -- Return image element instead of code block
  return pandoc.Para({
    pandoc.Image({}, output_path, "", {})
  })
end

-- Return the filter
return {
  {CodeBlock = CodeBlock}
}
