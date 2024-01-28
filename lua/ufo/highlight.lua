local cmd = vim.cmd
local api = vim.api
local fn = vim.fn

local event = require('ufo.lib.event')
local disposable = require('ufo.lib.disposable')

---@class UfoHighlight
local Highlight = {}
local initialized

---@type table<number|string, table>
local hlGroups

---@type table<string, string>
local signNames

local function resetHighlightGroup()
    local termguicolors = vim.o.termguicolors
    hlGroups = setmetatable({}, {
        __index = function(tbl, k)
            local ok, hl
            if type(k) == 'number' then
                ok, hl = pcall(api.nvim_get_hl_by_id, k, termguicolors)
            else
                ok, hl = pcall(api.nvim_get_hl_by_name, k, termguicolors)
            end
            if not ok or hl[vim.type_idx] == vim.types.dictionary then
                hl = {}
            end
            rawset(tbl, k, hl)
            return hl
        end
    })
    ok, hl = pcall(api.nvim_get_hl_by_name, 'Normal', termguicolors)
    cmd('hi default UfoFoldedFg ctermfg=None guifg=None')
    cmd('hi default UfoFoldedBg ctermfg=None guifg=None')

    cmd([[
        hi default link UfoPreviewSbar PmenuSbar
        hi default link UfoPreviewThumb PmenuThumb
        hi default link UfoPreviewWinBar UfoFoldedBg
        hi default link UfoPreviewCursorLine Visual
        hi default link UfoFoldedEllipsis Comment
        hi default link UfoCursorFoldedLine CursorLine
        hi default UfoFoldedBg ctermfg=None guifg=None
        hi default UfoFoldedFg ctermfg=None guifg=None
        hi default link UfoFoldedLineNr LineNr
    ]])
end

local function resetSignGroup()
    signNames = setmetatable({}, {
        __index = function(tbl, k)
            assert(fn.sign_define(k, {linehl = k}) == 0,
                'Define sign name ' .. k .. 'failed')
            rawset(tbl, k, k)
            return k
        end
    })
    return disposable:create(function()
        for _, name in pairs(signNames) do
            pcall(fn.sign_undefine, name)
        end
    end)
end

function Highlight.hlGroups()
    if not initialized then
        Highlight:initialize()
    end
    return hlGroups
end

function Highlight.signNames()
    if not initialized then
        Highlight:initialize()
    end
    return signNames
end

---
---@return UfoHighlight
function Highlight:initialize()
    if initialized then
        return self
    end
    self.disposables = {}
    event:on('ColorScheme', resetHighlightGroup, self.disposables)
    resetHighlightGroup()
    table.insert(self.disposables, resetSignGroup())
    initialized = true
    return self
end

function Highlight:dispose()
    disposable.disposeAll(self.disposables)
    self.disposables = {}
    initialized = false
end

return Highlight
