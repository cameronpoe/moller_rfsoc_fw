# write_bitstream pre-hook: USERID = first 8 hex digits of the git commit,
# or 0xFFFFFFFF if tracked files have uncommitted changes (or git fails).
if {[catch {exec git status --porcelain --untracked-files=no} dirty] || $dirty ne "" ||
    [catch {exec git rev-parse HEAD} hash]} {
    set userid 0xFFFFFFFF
} else {
    set userid 0x[string range $hash 0 7]
}
set_property BITSTREAM.CONFIG.USERID $userid [current_design]
