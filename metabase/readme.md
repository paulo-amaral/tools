
Added service to start at boot:

    sudo update-rc.d "metabase" defaults

I can now start the script, stop, see status with:

    sudo systemctl start/stop/status metabase

To see the last entries in the log, do:

    tail -f /opt/metabase/log/current
