# all/my/motd.ps1
function motd {
    $messages = @(
        "🧑‍💻 All my homies hate telemetry.",
        "🪓 All my homies hate the Witness.",
        "🚀 All my homies optimize startup.",
        "🔒 All my homies encrypt their files.",
        "📦 All my homies install Chocolatey.",
        "📉 All my homies kill memory leaks.",
        "🦑 All my homies commune with shell gods.",
        "⚡ All my homies use fast terminals.",
        "🧙 All my homies write DSLs like prophecy walls.",
        "🐚 All my homies hate overengineered syntax.",
        "🔼 All my homies rebuke the Final Shape.",
        "🎦 All my homies resist surveillance.",
        "🔥 All my homies hate slow boots.",
        "🌐 All my homies flush DNS like legends.",
        "🤖 All my homies install NVChad and vibe.",
        "🎯 All my homies return Ok or Err — never throw.",
        "🗂 All my homies tab-complete like it's magic.",
        "🎮 All my homies call out system processes like raid bosses.",
        "🌍 All my homies browse the web — but privately."
    )

    $pick = Get-Random -InputObject $messages
    WriteLine "$pick" -ForegroundColor Cyan
    return Ok
}