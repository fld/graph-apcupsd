# graph-apcupsd
Bash shell script for logging/graphing apcupsd on Debian jessie.

 * Logs parameters given by 'apaccess status' to a rrdtool-database
 * Generates multiple graphs with thumbnails
 * Generates a simple dynamic html/js thumbnail gallery for the graphs

![graph-apcupsd](http://i.imgur.com/Il1auzU.png "graph-apcupsd v1.1 Graph")
![graph-apcupsd](http://i.imgur.com/vy80B9u.png "graph-apcupsd v1.0 Web UI")
### Install ###
```
sudo apt-get install rrdtool apcupsd apcupsd-cgi imagemagick git
sudo git clone "git@github.com:fld/graph-apcupsd.git" /etc/apcupsd/
```
### Creating rrdtool database ###
Create a database for logging: _line voltage_, _load percentage_, _output voltage_, _internal temperature_, _battery voltage_ and number of _transfer events_ via _'apcaccess status'_.

I choose to go with a sampling frequency of _60 seconds_, because that is how often _'apcaccess status'_ updates it's values. The RRA row count of _'5256000'_ is enough for _10-years_ worth of data.
```
sudo rrdtool create /etc/apcupsd/apcupsd.rrd \
--step '60' \
'DS:LINEV:GAUGE:120:0:300' \
'DS:LOADPCT:GAUGE:120:0:300' \
'DS:OUTPUTV:GAUGE:120:0:300' \
'DS:ITEMP:GAUGE:120:0:128' \
'DS:BATTV:GAUGE:120:0:50' \
'DS:NUMXFERS:DERIVE:120:0:U' \
'DS:TONBATT:GAUGE:120:0:U' \
'RRA:LAST:0.5:1:5256000'
```

### Cron job ###
$ sudo crontab -e

Add:
```
*/1 * * * * /etc/apcupsd/cron-apcupsd.sh
*/1 * * * * /etc/apcupsd/graph-apcupsd.sh
```
alternatively it could be placed at: _/etc/cron.d/graph-apcupsd_

### Apache configuration ###
The default Apache configuration for _'apcupsd-cgi'_ needs to be tweaked to allow images and html content:
```
<FilesMatch \.png$>SetHandler image/png </FilesMatch>
<FilesMatch \.html$>SetHandler .html</FilesMatch>
```

For example, on Debian jessie:

_/etc/apache2/conf-enabled/serve-cgi-bin.conf_:
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
