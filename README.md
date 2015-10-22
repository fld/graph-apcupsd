# graph-apcupsd
cron shell script for logging/graphing apcupsd on Debian jessie.

![graph-apcupsd](http://i.imgur.com/vy80B9u.png =128x128 "graph-apcupsd v1.0 @ 1440x1000-resolution")
### Install ###
```
sudo apt-get install rrdtool apcupsd apcupsd-cgi imagemagick git
sudo git clone "git@github.com:fld/graph-apcupsd.git" /etc/apcupsd/
```
### Creating rrdtool database ###
```
sudo rrdtool create /etc/apcupsd/apcupsd.rrd \
--step '60' \
'DS:LINEV:GAUGE:120:0:300' \
'DS:LOADPCT:GAUGE:120:0:200' \
'DS:OUTPUTV:GAUGE:120:0:300' \
'DS:ITEMP:GAUGE:120:0:128' \
'DS:BATTV:GAUGE:120:0:300' \
'DS:NUMXFERS:COUNTER:120:0:65536' \
'RRA:LAST:0.5:1:5256000'
```

### Cron job ###
$ sudo crontab -e
```
*/1 * * * * /etc/apcupsd/cron-apcupsd.sh
```

### Apache configuration ###
/etc/apache2/conf-enabled/serve-cgi-bin.conf:
```
<IfModule mod_alias.c>
    <IfModule mod_cgi.c>
        Define ENABLE_USR_LIB_CGI_BIN
    </IfModule>

    <IfModule mod_cgid.c>
        Define ENABLE_USR_LIB_CGI_BIN
    </IfModule>

    <IfDefine ENABLE_USR_LIB_CGI_BIN>
        ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
        <Directory "/usr/lib/cgi-bin">
            AllowOverride None
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
            Require all granted
            <FilesMatch \.png$>
                SetHandler image/png
            </FilesMatch>
            <FilesMatch \.html$>
                SetHandler .html
            </FilesMatch>
        </Directory>
    </IfDefine>
</IfModule>
```

### Viewing statistics ###
By default, the script generates __index.html__ and __\<time_period\>[s].png__ files to: __/usr/lib/cgi-bin/apcupsd/__ which (by default) is accessible at: <http://localhost/cgi-bin/apcupsd/>
