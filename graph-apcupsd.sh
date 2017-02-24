#!/bin/bash
export LC_ALL='en_US.UTF-8'
rrd_location='/etc/apcupsd/apcupsd.rrd'
rrd_graphdir='/usr/lib/cgi-bin/apcupsd'

# 1% LOADPCT measures: ?.?? Watts
lwmult='13.5'

# 1 kWh => x.xxx EUR
kwhmult='0.1014'

### Web page
gen_gallery=1            # Generate index.html
gen_favicon=1            # Generate favicon.png
favicon_source='1hs.png' # Use 1h thumbnail
favicon_size='32x32'     # 32px size

### Colors / Theme
# http://oss.oetiker.ch/rrdtool/doc/rrdgraph.en.html
# http://oss.oetiker.ch/rrdtool/doc/rrdgraph_graph.en.html
#
rrd_font='DEFAULT:0:DroidSansMono Bold'
period_fmt='%a %d %b %H\:%M %Y'
occur_fmt='%d %b %H\:%M'
cur_fmt='€' # cur_fmt="$(locale cur_fmt_symbol)"

# 'rrdgraph -c'-colors:
RRCA='FONT#CBA13A'
RRCB='BACK#151515'
RRCC='CANVAS#1D1D1D'
RRCD='AXIS#CC0000'
RRCE='GRID#888888'
RRCF='MGRID#900000'
RRCG='SHADEA#696969'
RRCH='SHADEB#393939'
RRCI='ARROW#00BB00'
RRC1='#FF000060' # Power HRULE

# '--pango-markup'-colors:
PANA='#9A6D20'   # Primary <span>
PANB='#624514'   # Secondary <span>
PAN1='#2C72C7'   # BATTV
PAN2='#FF6868'   # XFER
PAN3='#00C0C0'   # POWER
PAN4='#648B25'   # LINEV
PAN5='#A0DA43'   # OUTPUTV
PAN6='#FFFFFF70' # TONBATT

unset thumbs_html
# Graph period/steps
for period in 1h/60 6h/60 1d/120 3d/300 5d/600 1w/600 1m/3600 3m/10800 1y/43200 3y/129600 5y/216000; do
    step=$(basename "$period")
    period=$(dirname "$period")
    # Graph width/height[/thumb]
    for canvas in 800/300 200/108/thumb; do
        if [[ $(basename "$canvas") == 'thumb' ]]; then
            suffix='s' # Thumbnail filename-suffix
            extarg='--only-graph' # rrdtool thumbnail arg.
            canvas="$(dirname "$canvas")"
        else
            unset suffix
            unset extarg
        fi      
        # http://oss.oetiker.ch/rrdtool/doc/rrdgraph_data.en.html
        # http://oss.oetiker.ch/rrdtool/doc/rrdgraph_rpn.en.html
        #
        rrdtool graph "$rrd_graphdir/$period$suffix.png" \
        --title "apcupsd: $period power statistics ($((step/60))-min avgs.)" \
        --right-axis '0.1:0' \
        --vertical-label 'Volts / Watts / Watthours' \
        --right-axis-label 'Battery voltage' \
        --width "$(dirname "$canvas")" \
        --height "$(basename "$canvas")" \
        $extarg \
        --step "$step" \
        --start "end-$period" \
        -c $RRCA -c $RRCB -c $RRCC -c $RRCD -c $RRCE -c $RRCF -c $RRCG -c $RRCH -c $RRCI \
        --pango-markup \
        --font "$rrd_font" \
        --watermark "$(date) / kWh price: $kwhmult $cur_fmt" \
        "DEF:ds0=$rrd_location:LINEV:LAST" \
        "DEF:ds1=$rrd_location:LOADPCT:LAST" \
        "DEF:ds2=$rrd_location:OUTPUTV:LAST" \
        "DEF:ds3=$rrd_location:ITEMP:LAST" \
        "DEF:ds4=$rrd_location:BATTV:LAST" \
        "DEF:ds5=$rrd_location:NUMXFERS:LAST" \
        "DEF:ds6=$rrd_location:TONBATT:LAST" \
        "CDEF:numsteps=ds0,UN,COUNT,MAX,1,-" \
        "CDEF:power=ds1,$lwmult,*" \
        "CDEF:wh=power,UN,0,power,60,/,60,/,IF" \
        "CDEF:kwh=wh,1000,/" \
        "CDEF:cost=kwh,$kwhmult,*" \
        "CDEF:batv=ds4,10,*" \
        "CDEF:hronbat=ds6,60,/,60,/" \
        "CDEF:whonbat=hronbat,0,EQ,UNKN,hronbat,power,*,IF" \
        "CDEF:ds60=ds6,UN,0,ds6,IF" \
        "CDEF:batpower=ds60,0,EQ,0,power,60,/,60,/,IF" \
        "CDEF:onbat=ds60,0,EQ,0,1,IF,60,/,60,/,$(($step/60)),/" \
        "CDEF:daily=power,1000,/,24,*,$kwhmult,*" \
        "CDEF:weekly=power,1000,/,24,*,7,*,$kwhmult,*" \
        "CDEF:monthly=power,1000,/,24,*,30,*,$kwhmult,*" \
        "CDEF:yearly=power,1000,/,24,*,365,*,$kwhmult,*" \
        "VDEF:kwh_total=kwh,TOTAL" \
        "VDEF:cost_total=cost,TOTAL" \
        "VDEF:whonbat_MAX=whonbat,MAXIMUM" \
        "VDEF:whonbat_TOTAL=whonbat,TOTAL" \
        "VDEF:batpower_TOTAL=batpower,TOTAL" \
        "VDEF:onbat_TOTAL=onbat,TOTAL" \
        "VDEF:ds0_MIN=ds0,MINIMUM" \
        "VDEF:ds0_MAX=ds0,MAXIMUM" \
        "VDEF:ds0_AVG=ds0,AVERAGE" \
        "VDEF:ds0_FIRST=ds0,FIRST" \
        "VDEF:ds0_LAST=ds0,LAST" \
        "VDEF:ds1_MAX=ds1,MAXIMUM" \
        "VDEF:ds1_LAST=ds1,LAST" \
        "VDEF:ds2_MIN=ds2,MINIMUM" \
        "VDEF:ds2_MAX=ds2,MAXIMUM" \
        "VDEF:ds2_AVG=ds2,AVERAGE" \
        "VDEF:ds2_LAST=ds2,LAST" \
        "VDEF:ds3_MAX=ds3,MAXIMUM" \
        "VDEF:ds3_LAST=ds3,LAST" \
        "VDEF:ds4_MIN=ds4,MINIMUM" \
        "VDEF:ds4_MAX=ds4,MAXIMUM" \
        "VDEF:ds4_LAST=ds4,LAST" \
        "VDEF:ds5_TOTAL=ds5,TOTAL" \
        "VDEF:ds6_LAST=ds6,LAST" \
        "VDEF:power_MIN=power,MINIMUM" \
        "VDEF:power_MAX=power,MAXIMUM" \
        "VDEF:power_AVG=power,AVERAGE" \
        "VDEF:power_LAST=power,LAST" \
        "VDEF:daily_AVG=daily,AVERAGE" \
        "VDEF:weekly_AVG=weekly,AVERAGE" \
        "VDEF:monthly_AVG=monthly,AVERAGE" \
        "VDEF:yearly_AVG=yearly,AVERAGE" \
        "GPRINT:ds0_FIRST:<span foreground='$PANB'>$period_fmt</span> -\r:strftime" \
        "COMMENT:\u" \
        "TEXTALIGN:center" \
        "GPRINT:kwh_total:Energy consumed\: <span size='larger' foreground='$PANA'>%.1lf kWh</span>\g" \
        "GPRINT:cost_total: / <span size='larger' foreground='$PANA'>%.2lf $cur_fmt</span>\c" \
        "GPRINT:ds0_LAST: <span foreground='$PANA'>$period_fmt</span>  \r:strftime" \
        "TEXTALIGN:left" \
        "COMMENT:  UPS load         " \
        "GPRINT:ds1_LAST:<span foreground='$PANA'>%3.1lf %%</span>" \
        "GPRINT:ds1_MAX: max\: <span foreground='$PANA'>%3.1lf %%</span>\g" \
        "GPRINT:ds1_MAX:  (<span foreground='$PANB'>$occur_fmt</span>)\n:strftime" \
        "COMMENT:  Temperature      " \
        "GPRINT:ds3_LAST:<span foreground='$PANA'>%3.1lf °C</span>" \
        "GPRINT:ds3_MAX:max\: <span foreground='$PANA'>%3.1lf °C</span>\g" \
        "GPRINT:ds3_MAX: (<span foreground='$PANB'>$occur_fmt</span>)\n:strftime" \
        "LINE1:batv$PAN1:Battery voltage  :skipscale" \
        "GPRINT:ds4_LAST:<span foreground='$PAN1'>%3.1lf V</span>" \
        "GPRINT:ds4_MAX: max\: <span foreground='$PAN1'>%3.1lf V</span>\g" \
        "GPRINT:ds4_MAX:  (<span foreground='$PANB'>$occur_fmt</span>):strftime" \
        "GPRINT:ds4_MIN:min\: <span foreground='$PAN1'>%3.1lf V</span>\g" \
        "GPRINT:ds4_MIN: (<span foreground='$PANB'>$occur_fmt</span>)\n:strftime" \
        "COMMENT:\u" \
        "GPRINT:daily_AVG:Average cost per/\tday\: <span foreground='$PANA'>%.2lf $cur_fmt</span>\r" \
        "COMMENT: \n" \
        "COMMENT:\u" \
        "GPRINT:weekly_AVG:\tweek\: <span foreground='$PANA'>%.2lf $cur_fmt</span>\r" \
        "TICK:ds5${PAN2}:-0.5:Transfer events\: " \
        "GPRINT:ds5_TOTAL:<span foreground='$PAN2'>%.0lf</span>" \
        "COMMENT:\u" \
        "GPRINT:monthly_AVG:\tmonth\: <span foreground='$PANA'>%.1lf $cur_fmt</span>\r" \
        "AREA:whonbat$PAN6:Battery usage    " \
        "GPRINT:onbat_TOTAL:<span foreground='$PANA'>%.2lf hr</span> /" \
        "GPRINT:batpower_TOTAL:<span foreground='$PANA'>%.2lf Wh</span>" \
        "GPRINT:ds6_LAST:TONBATT\: <span foreground='$PANA'>%.0lf sec</span>\n" \
        "COMMENT:\u" \
        "GPRINT:yearly_AVG:\t\t\tyear\:  <span foreground='$PANA'>%.0lf $cur_fmt</span>\r" \
        "AREA:power${PAN3}60:" \
        "LINE1:power$PAN3:Power consumption" \
        "GPRINT:power_MIN:min\: <span foreground='$PAN3'>%6.1lf W</span>" \
        "GPRINT:power_MAX:max\: <span foreground='$PAN3'>%6.1lf W</span>" \
        "GPRINT:power_AVG:avg\: <span foreground='$PAN3'>%6.1lf W</span>" \
        "GPRINT:power_LAST:last\: <span foreground='$PAN3' size='larger'>%6.1lf W</span>\n" \
        "AREA:ds0${PAN4}90:Line voltage     " \
        "GPRINT:ds0_MIN:min\: <span foreground='$PAN4'>%6.1lf V</span>" \
        "GPRINT:ds0_MAX:max\: <span foreground='$PAN4'>%6.1lf V</span>" \
        "GPRINT:ds0_AVG:avg\: <span foreground='$PAN4'>%6.1lf V</span>" \
        "GPRINT:ds0_LAST:last\: <span foreground='$PAN4'>%6.1lf V</span>\n" \
        "LINE1:ds2$PAN5:Output voltage   " \
        "GPRINT:ds2_MIN:min\: <span foreground='$PAN5'>%6.1lf V</span>" \
        "GPRINT:ds2_MAX:max\: <span foreground='$PAN5'>%6.1lf V</span>" \
        "GPRINT:ds2_AVG:avg\: <span foreground='$PAN5'>%6.1lf V</span>" \
        "GPRINT:ds2_LAST:last\: <span foreground='$PAN5'>%6.1lf V</span>\n" \
        "HRULE:power_LAST$RRC1:" \
        "COMMENT:\s" > /dev/null
    done
    thumbs_html="$thumbs_html            "
    thumbs_html="$thumbs_html<div class=\"thumb\"><a href=\"#\" rel=\"$period.png\" class=\"thref\">"
    thumbs_html="$thumbs_html<img src=\"${period}s.png\" /></a><div>$period</div></div>\n"
done

if ((gen_gallery)); then
    cat << 'EOF' > "$rrd_graphdir/index.html"
<!DOCTYPE HTML>
<html>
<head>
    <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
    <link rel="icon" type="image/png" href="favicon.png" />
    <meta http-equiv="refresh" content="60" />
    <title>graph-apcupsd</title>
    <style>
        body { background-color:#121212; color:#DC9C2D; font-family:monospace; }
        a { outline: 0; color:#624514; text-decoration: none; }
        a:hover { color:#DC9C2D; }
        #viewer { text-align:center; }
        .thumb { float:left; margin:10px; padding:2px; opacity:0.60; border:1px solid #624514; }
        .thumb.hover, .thumb:hover { opacity:1.0; box-shadow:0 0 10px #624514; }
        .thumb div { margin-left:5px; margin-bottom:3px; margin-top:3px; font-size:12px; background-color:black; }
        #footer { position:fixed; bottom: 0; width:100%; padding: 3px; background-color:#000000; text-align:center; font-size:10px; }
    </style>
    <script src="http://code.jquery.com/jquery-1.11.3.min.js"></script>
    <script>
        $(document).ready(function() {
            if (localStorage.getItem('lastImage')) {
                var image = localStorage.getItem('lastImage');
                $('#viewer').html('<img src="'+image+'"/>');
                $('a').filter("[rel='"+image+"']").parent().addClass("hover");
            }
            $(".thref").click(function() {
                var image = $(this).attr("rel");
                localStorage.setItem('lastImage', image);
                $('#viewer').html('<img src="'+image+'"/>');
            });
            $(".thumb").click(function() {
                $(".thumb.hover").removeClass("hover");
                $(this).addClass("hover");
            });
        });
    </script>
</head>
<body>
    <section>
        <div id="thumbnails">
            <div id="viewer"><img src="" alt="Select a graph to view:" border="0" /></div>
EOF
    echo -e "${thumbs_html::-2}" >> "$rrd_graphdir/index.html"
    cat << 'EOF' >> "$rrd_graphdir/index.html"
        </div>
    </section>
    <footer><div id="footer"><a href="https://github.com/fld/graph-apcupsd">graph-apcupsd v1.1</a></div></footer>
</body></html>
EOF
fi

((gen_favicon)) &&
    convert -bordercolor white -border 0 -alpha off -colors 256 -resize "$favicon_size" "$rrd_graphdir/$favicon_source" "$rrd_graphdir/favicon.png"
