add-content -path /User/biswanathdehury/.ssh/config -value @'

Host ${hostname}
    HostName ${hostname}
    User ${user}
    IdentityFile ${indentityfile}
'@