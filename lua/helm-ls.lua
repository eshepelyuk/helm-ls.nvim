-- main module file

---@class Config
---@field conceal_templates table
---@field indent_hints table
---@field opt string Your config option
local config = {
  conceal_templates = {
    enabled = true,
  },
  indent_hints = {
    enabled = true,
    only_for_current_line = true,
  },
}

---@class MyModule
local M = {}

---@type Config
M.config = config

-- Function to handle indent hints
local function handle_indent_hints(indent_hints)
  if M.config.indent_hints.enabled then
    indent_hints.add_indent_hints()
  end
end

-- Function to handle conceal templates
local function handle_conceal_templates(conceal)
  if M.config.conceal_templates.enabled then
    local clients = vim.lsp.get_clients({ bufnr = vim.api.nvim_get_current_buf(), name = "helm_ls" })
    if vim.tbl_isempty(clients) then
      return
    end
    conceal.conceal_templates_with_hover()
    conceal.clear_extmark_if_cursor_on_line()
  end
end

---@param args Config?
M.setup = function(args)
  -- Validate and merge configuration
  if args then
    if args.conceal_templates and type(args.conceal_templates) ~= "table" then
      error("Invalid type for conceal_templates")
    end
    if args.indent_hints and type(args.indent_hints) ~= "table" then
      error("Invalid type for indent_hints")
    end
  end

  M.config = vim.tbl_deep_extend("force", M.config, args or {})

  local conceal = nil
  local indent_hints = nil

  if M.config.conceal_templates.enabled then
    conceal = require("helm-ls.conceal")
    conceal.set_config(M.config.conceal_templates)
  end

  if M.config.indent_hints.enabled then
    indent_hints = require("helm-ls.indent-hints")
    indent_hints.set_config(M.config.indent_hints)
  end

  -- Create the autocommand group "ConcealWithLsp"
  local group_id = vim.api.nvim_create_augroup("ConcealWithLsp", { clear = true })

  -- Define file patterns as constants
  local file_patterns = { "*.yaml", "*.yml", "*.helm", "*.tpl" }

  -- Define the autocommand
  vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
    group = group_id,
    pattern = file_patterns,
    callback = function()
      if vim.bo.filetype ~= "helm" then
        return
      end
      if indent_hints then
        handle_indent_hints(indent_hints)
      end
      if conceal then
        handle_conceal_templates(conceal)
      end
    end,
  })
end


return M
