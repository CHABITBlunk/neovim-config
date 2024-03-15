-- git lua api
--
-- load w `local git = require "habit.utils.git"`

local git = { url = "https://github.com/" }

local function trim_or_nil(str) return type(str) == "string" and vim.trim(str) or nil end

-- run a git command from install directory
---@param args string|string[] the git args
---@return string|nil # the result of the command or nil if unsuccessful
function git.cmd(args)
  if type(args) == "string" then args = { args } end
  return require("habit.utils").cmd(vim.list_extend({ "git", "-C", habit.install.home }, args))
end

-- get 1st worktree that a file belongs to
---@param file string? the file to check, defaults to current file
---@param worktrees table<string, string>[]? an array-like table of worktrees with entries `toplevel` and `gitdir`, default retrieves from `vim.g.git_worktrees`
---@return table<string, string>|nil # a table specifying `toplevel` & `gitdir` of worktree or nil if not found
function git.file_worktree(file, worktrees)
  worktrees  = worktrees or vim.g.git_worktrees
  if not worktrees then return end
  file = file or vim.fn.expand "%"
  for _, worktree in ipairs(worktrees) do
    if
      require("habit.utils").cmd({
        "git",
        "--work_tree",
        worktree.toplevel,
        "--git-dir",
        worktree.gitdir,
        "ls-files",
        "--error-unmatch",
        file,
      })
    then
      return worktree
    end
  end
end

-- check if vim is able to reach `git`
---@return boolean # the result of running `git --help`
function git.available() return vim.fn.executable "git" == 1 end

-- check git client version number
---@return table|nil # a table with version info or nil if there is an error
function git.git_version()
  local output = git.cmd({ "--version" })
  if output then
    local version_str = output:match "%d+%.%d+%.%d"
    local major, min, patch = unpack(vim.tbl_map(tonumber, vim.split(version_str, "%.")))
    return { major = major, min = min, patch = patch, str = version_str }
  end
end

-- check if a branch contains a commit
---@param remote string the git remote to check
---@param branch string the git branch to check
---@param commit string the git commit to check
---@return boolean # the result of the command
function git.branch_contains(remote, branch, commit)
  return git.cmd({ "merge-base", "--is-ancestor", commit, remote .. "/" .. branch }) ~= nil
end

-- get remote name for a given branch
---@param branch string the git branch to check
---@return string|nil # the name of the remote for the given branch
function git.branch_remote(branch) return trim_or_nil(git.cmd({ "config", "branch." .. branch .. ".remote" })) end

-- add a git remote
---@param remote string the remote to add
---@param url string the url of the remote
---@return string|nil # the result of the command
function git.remote_update(remote, url) return git.cmd({ "remote", "set-url", remote, url }) end

-- get url of given git remote
---@param remote string the remote to get the url of
---@return string|nil # the url of the remote
function git.remote_url(remote) return trim_or_nil(git.cmd({ "remote", "get-url", remote })) end

-- get branches from a git remote
---@param remote string the remote for which we set up branches
---@param branch string the branch to set up
---@return string|nil # the result of the command
function git.remote_set_branches(remote, branch) return git.cmd({ "remote", "set-branches", remote, branch}) end

-- get current version with git describe including tags
---@return string|nil # the current git describe string
function git.current_version() return trim_or_nil(git.cmd({ "describe", "--tags" })) end

-- get current branch
---@return string|nil # the branch of my nvim config installation
function git.current_branch() return trim_or_nil(git.cmd({ "rev-parse", "--abbrev-ref", "HEAD" })) end

-- verify a reference
---@return string|nil # the referenced commit
function git.ref_verify(ref) return trim_or_nil(git.cmd({ "rev-parse", "--verify", ref })) end

-- get current head of git repo
---@return string|nil # the head string
function git.local_head() return trim_or_nil(git.cmd({ "rev-parse", "HEAD" })) end

-- get current head of git remote
---@param remote string the remote to check
---@param branch string the branch to check
---@return string|nil # the head string of the remote branch
function git.remote_head(remote, branch)
  return trim_or_nil(git.cmd({ "rev-list", "-n", "1", remote .. "/" .. branch }))
end

-- get commit hash of given tag
---@param tag string the tag to resolve
---@return string|nil # the commit hash of a git tag
function git.tag_commit(tag) return trim_or_nil(git.cmd({ "rev-list", "-n", "1", tag })) end

-- get commit log between 2 commit hashes
---@param start_hash? string the start commit hash
---@param end_hash? string the end commit hash
---@return string[] # an array-like table of commit messages
function git.get_commit_range(start_hash, end_hash)
  local range = start_hash and end_hash and start_hash .. ".." .. end_hash or nil
  local log = git.cmd({ "log", "--no-merges", '--pretty="format:[%h] %s"', range })
  return log and vim.fn.split(log, "\n") or {}
end

-- get a list of all tags with a regex filter
---@param search? string a regex to search the tags with (defaults to "v*" for version tags)
---@return string[] # an array-like table of tags that match the search
function git.get_versions(search)
  local tags = git.cmd({ "tag", "-l", "--sort=version:refname", search == "latest" and "v*" or search })
  return tags and vim.fn.split(tags, "\n") or {}
end

-- get latest version of a list of versions
---@param versions? table a list of versions to search(defaults to all versions available)
---@param string|nil # the latest version from the array
function git.latest_version(versions)
  if not versions then versions = git.get_versions() end
  return versions[#versions]
end

-- parse a remote url
---@param str string the remote to parse into a full git url
---@return string # the full git url for the given remote string
function git.parse_remote_url(str)
  return vim.fn.match(str, require("habit.utils").url_matcher) == -1
      and git.url .. str .. (vim.fn.match(str, "/") == -1 and "/neovim-config.git" or ".git")
    or str
end

-- check if a conventional commit commit message is breaking or not
---@param commit string a commit message
---@return boolean # true if message is breaking, false if commit message not breaking
function git.is_breaking(commit) return vim.fn.match(commit, "\\[.*\\]\\s\\+\\w\\+\\((\\w\\+)\\)\\?!:") ~= -1 end

-- get a list of breaking commits from commit messages using conventional commit standard
---@param commits string[] an array-like table of commit messages
---@return string[] # an array-like table of commits that are breaking
function git.breaking_changes(commits) return vim.tbl_filter(git.is_breaking, commits) end

-- generate a table of comit messages for nvim's echo api with highlighting
---@param commits string[] an array-like table of commit messages
---@return string[][] changelog an array-like table of echo messages to provide to nvim_echo or habit.echo
function git.pretty_changelog(commits)
  local changelog = {}
  for _, commit in ipairs(commits) do
    local hash, type, msg = commit:match "(%[.*%])(.*:)(.*)"
    if hash and type and msg then
      vim.list_extend(changelog, {
        { hash, "DiffText" },
        { type, git.is_breaking(commit) and "DiffDelete" or "DiffChange" },
        { msg },
        { "\n" },
      })
    end
  end
  return changelog
end

return git
