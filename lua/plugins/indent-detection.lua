return {
  -- Auto-detect indentation (tabs vs spaces, indent width)
  {
    "tpope/vim-sleuth",
    event = { "BufReadPre", "BufNewFile" },
  },
}
