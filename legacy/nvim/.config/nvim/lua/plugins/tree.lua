return {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
        filesystem = {
            filtered_items = {
                hide_dotfiles = false,   -- show dotfiles
                hide_gitignored = false, -- show gitignored files
            },
            follow_current_file = {
                enabled = true,            -- focus on the current file in the tree
            },
            use_libuv_file_watcher = true, -- use libuv for file watching
        },
        window = {
            width = 25,
        },
    },
}
