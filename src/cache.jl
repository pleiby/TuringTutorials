const REPO_URL = "https://github.com/TuringLang/TuringTutorials"
const CLONED_DIR = joinpath(REPO_DIR, "ClonedTuringTutorials")

"""
    clean_weave_cache()

On the one hand, we need `cache = :all` to have quick builds.
On the other hand, we don't need cache files committed to the repo which break the build.
Therefore, this method manually cleans the cache just to be sure.
"""
function clean_weave_cache()
    for (root, dirs, files) in walkdir(pkgdir(TuringTutorials); onerror=x->())
        if "cache" in dirs
            cache_dir = joinpath(root, "cache")
            rm(cache_dir; force=true, recursive=true)
        end
    end
end

"""
    clone_tutorials_output()

Ensure that `$CLONED_DIR` exists and contains the latest commit from the output branch for `$REPO_URL`.
"""
function clone_tutorials_output()
    branch = "artifacts"
    args = [
        "clone",
        "--depth=1",
        "--branch=$branch"
    ]
    if isdir(CLONED_DIR)
        cd(CLONED_DIR) do
            run(`git checkout $branch`)
            run(`git pull`)
        end
    else
        run(`git $args $REPO_URL $CLONED_DIR`)
    end
end

function file_changed(old_dir, new_dir, file)
    old_path = joinpath(old_dir, file)
    new_path = joinpath(new_dir, file)
    old = read(old_path, String)
    new = isfile(new_path) ? read(new_path, String) : ""
    return old != new
end

"""
    any_changes(tutorial::String)

Return whether there are any changes for the local source files, such as `.jmd` and `Manifest.toml`,
compared to the files in `$CLONED_DIR`.
"""
function any_changes(tutorial::String)
    old_dir = joinpath(CLONED_DIR, "tutorials", tutorial)
    new_dir = joinpath(REPO_DIR, "tutorials", tutorial)
    files = readdir(old_dir)
    files = filter(!=(WEAVE_LOG_FILE), files)
    any(file_changed.(old_dir, new_dir, files))
end

"""
    changed_tutorials()

Return the tutorials which have changed compared to the output branch at $REPO_URL.
"""
function changed_tutorials()
    clone_tutorials_output()
    T = tutorials()
    changed = filter(any_changes, T)
    println("Found changes for the tutorials $changed ($(length(changed))/$(length(T)))")
    changed
end
