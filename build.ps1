# a rudimentary build scripts. fixes encoding and installs the
# module opening a new powershell instance for the tests.
function build {
    & ./fix-encoding.ps1
    & ./install.ps1
    # After installing, open a new powershell instance for the tests.
    & all my terminal
}

build
