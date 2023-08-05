-- vim: set sw=2 ts=2 sts=2 foldmethod=marker:

local lspconfig = require('lspconfig')

vim.lsp.handlers['$ccls/call'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No methods found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Callees';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

function RequestCall()
  local params = vim.lsp.util.make_position_params()
  params.callee = true
  vim.lsp.buf_request(0, '$ccls/call', params)
end

vim.lsp.handlers['$ccls/member'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No members found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Members';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

function RequestMemVar()
  local params = vim.lsp.util.make_position_params()
  params.kind = 0
  vim.lsp.buf_request(0, '$ccls/member', params)
end

function RequestMemFun()
  local params = vim.lsp.util.make_position_params()
  params.kind = 3
  vim.lsp.buf_request(0, '$ccls/member', params)
end

function RequestMemType()
  local params = vim.lsp.util.make_position_params()
  params.kind = 2
  vim.lsp.buf_request(0, '$ccls/member', params)
end

vim.lsp.handlers['$ccls/vars'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No instances found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Instances';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

function RequestInstances()
  local params = vim.lsp.util.make_position_params()
  vim.lsp.buf_request(0, '$ccls/vars', params)
end

vim.lsp.handlers['$ccls/inheritance'] = function(_, res, ctx, _)
  if not res or vim.tbl_isempty(res) then
    vim.notify('No classes found')
  else
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    vim.fn.setqflist({}, ' ', {
      title = 'Classes';
      items = vim.lsp.util.locations_to_items(res, client.offset_encoding);
      context = ctx;
    })
    vim.api.nvim_command("botright copen")
  end
end

function RequestBaseClass()
  local params = vim.lsp.util.make_position_params()
  params.derived = false
  vim.lsp.buf_request(0, '$ccls/inheritance', params)
end

function RequestDerivedClass()
  local params = vim.lsp.util.make_position_params()
  params.derived = true
  vim.lsp.buf_request(0, '$ccls/inheritance', params)
end

function RequestRoleWrite()
  local params = vim.lsp.util.make_position_params()
  params.role = 16
  vim.lsp.buf_request(0, 'textDocument/references', params)
end

function RequestRoleRead()
  local params = vim.lsp.util.make_position_params()
  params.role = 8
  vim.lsp.buf_request(0, 'textDocument/references', params)
end

function InstallHighlight(install)
  if install then
    vim.cmd('autocmd CursorHold <buffer> lua vim.lsp.buf.document_highlight()')
    vim.cmd('autocmd CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()')
    vim.cmd('autocmd CursorMoved <buffer> lua vim.lsp.buf.clear_references()')
  else
    vim.cmd("autocmd! CursorHold")
    vim.cmd("autocmd! CursorHoldI")
    vim.cmd("autocmd! CursorMoved")
  end
end

function FreezeHighlight(freeze)
  if freeze then
    InstallHighlight(false)
    vim.cmd("lua vim.lsp.buf.document_highlight()")
  else
    vim.cmd("lua vim.lsp.buf.clear_references()")
    InstallHighlight(true)
  end
end

local set_keymaps = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
  buf_set_keymap('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
  buf_set_keymap('i', '<C-k>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
  buf_set_keymap('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
  buf_set_keymap('n', '<leader>qf', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)

  buf_set_keymap('n', '<leader>cal', '<cmd>lua RequestCall()<CR>', opts)
  buf_set_keymap('n', '<leader>mv', '<cmd>lua RequestMemVar()<CR>', opts)
  buf_set_keymap('n', '<leader>mf', '<cmd>lua RequestMemFun()<CR>', opts)
  buf_set_keymap('n', '<leader>mt', '<cmd>lua RequestMemType()<CR>', opts)
  buf_set_keymap('n', '<leader>inst', '<cmd>lua RequestInstances()<CR>', opts)
  buf_set_keymap('n', '<leader>bas', '<cmd>lua RequestBaseClass()<CR>', opts)
  buf_set_keymap('n', '<leader>der', '<cmd>lua RequestDerivedClass()<CR>', opts)
  -- buf_set_keymap('n', '<leader>wr', '<cmd>lua RequestRoleWrite()<CR>', opts)
  -- buf_set_keymap('n', '<leader>rd', '<cmd>lua RequestRoleRead()<CR>', opts)

  buf_set_keymap('n', '<leader>sym', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', opts)
  buf_set_keymap('n', '<leader>gsym', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', opts)
  buf_set_keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts)
  buf_set_keymap('n', '[d', '<cmd>lua vim.diagnostic.goto_prev({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', ']d', '<cmd>lua vim.diagnostic.goto_next({severity = vim.diagnostic.severity.ERROR;})<CR>', opts)
  buf_set_keymap('n', '<leader>dig', '<cmd>lua vim.diagnostic.setqflist()<CR>', opts)
end

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local set_keymaps_and_hl = function(client, bufnr)
  InstallHighlight(true)
  set_keymaps(client, bufnr)
end

function GetRootDirWrapper(filename, bufnr)
  local res = vim.api.nvim_call_function("GetRootDir", {filename, bufnr})
  if res == '' then
    return nil
  else
    return res
  end
end

lspconfig.ccls.setup {
  root_dir = GetRootDirWrapper,
  init_options = {
    dotCclsWhitelist = {},
    dotCclsBlacklist = {"ccls-cache", ".ccls-cache", "ambarella", "build"},
    cache = {
      directory = "ccls-cache"
    },
    highlight = {
      lsRanges = true
    },
    index = {
      whitelist = {},
      blacklist = {}
    },
  },
  on_attach = set_keymaps_and_hl,
  flags = {
    debounce_text_changes = 150
  },
  -- Uncomment for debug log
  -- cmd = { "/usr/bin/ccls", "-log-file=/tmp/ccls.log", "-v=1"}
  -- cmd = { "/usr/bin/ccls" }
  cmd = { "/home/shs1sf/ccls/install/bin/ccls" }
  -- cmd = {"/home/shs1sf/viml-server/lsp/a.out"},
}

lspconfig.pyright.setup {
  cmd = {"/home/shs1sf/pyright_conda.sh"},
  root_dir = lspconfig.util.root_pattern(".git"),
  on_attach = set_keymaps_and_hl
}

lspconfig.vimls.setup {
  cmd = {"/home/shs1sf/viml-server/lsp/a.out"},
  root_dir = function(a, b) return "/home/shs1sf/viml-server/root_dir" end,
  on_attach = set_keymaps_and_hl,
  filetypes = { 'vim' },
  single_file_support = true
}



function ListWorkspaces()
  local workspace_folders = {}
  for _, client in pairs(vim.lsp.get_active_clients()) do
    for _, folder in pairs(client.workspace_folders or {}) do
      table.insert(workspace_folders, folder.name)
    end
  end
  return workspace_folders
end

function ListFilteredSymbols(filter)
  local function on_list(options)
    vim.fn.setqflist({}, ' ', options)
    vim.api.nvim_command('Cfilter ' .. filter)
    vim.api.nvim_command('copen')
  end
  vim.lsp.buf.document_symbol{on_list=on_list}
end
