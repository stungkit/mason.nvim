local process = require "mason.core.process"
local installer = require "mason.core.installer"
local _ = require "mason.core.functional"
local path = require "mason.core.path"
local platform = require "mason.core.platform"

local M = {}

local create_bin_path = _.if_else(_.always(platform.is.win), _.format "%s.exe", _.identity)

---@param package string
local function with_receipt(package)
    return function()
        local ctx = installer.context()
        ctx.receipt:with_primary_source(ctx.receipt.dotnet(package))
    end
end

---@async
---@param package string
---@param opt { bin: string[] | nil } | nil
function M.package(package, opt)
    return function()
        return M.install(package, opt).with_receipt()
    end
end

---@async
---@param package string
---@param opt { bin: string[] | nil } | nil
function M.install(package, opt)
    local ctx = installer.context()
    ctx.spawn.dotnet {
        "tool",
        "update",
        "--tool-path",
        ".",
        ctx.requested_version
            :map(function(version)
                return { "--version", version }
            end)
            :or_else(vim.NIL),
        package,
    }

    if opt and opt.bin then
        if opt.bin then
            _.each(function(executable)
                ctx:link_bin(executable, create_bin_path(executable))
            end, opt.bin)
        end
    end

    return {
        with_receipt = with_receipt(package),
    }
end

function M.env(root_dir)
    return {
        PATH = process.extend_path { root_dir },
    }
end

return M