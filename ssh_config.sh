#!/bin/bash

if grep -q "X11Forwarding" /etc/ssh/sshd_config; then
    sed -i 's/X11Forwarding.*$/X11Forwarding yes/g' /etc/ssh/sshd_config
else
    echo "X11Forwarding yes" >> /etc/ssh/sshd_config
fi
if grep -q "X11UseLocalhost" /etc/ssh/sshd_config; then
    sed -i 's/X11UseLocalhost.*$/X11UseLocalhost no/g' /etc/ssh/sshd_config
else
    echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
fi
if grep -q "PermitRootLogin" /etc/ssh/sshd_config; then
    sed -i 's/PermitRootLogin.*$/PermitRootLogin yes/g' /etc/ssh/sshd_config
else
    echo "PermitRootLogin yes">> /etc/ssh/sshd_config
fi
if grep -q "ClientAliveInterval" /etc/ssh/sshd_config; then
    sed -i 's/ClientAliveInterval.*$/ClientAliveInterval 60/g' /etc/ssh/sshd_config
else
    echo "ClientAliveInterval 60" >> /etc/ssh/sshd_config
fi
