                 Redmine Wiki External Filter Plugin
                 ===================================
              Copyright (C) 2010 Alexander Tsvyashchenko,
              http://www.ndl.kiev.ua - see COPYRIGHT.txt

Overview
========

This plugin allows defining macros that process macro argument using
external filter program and render its result in Redmine wiki.

For every filter two macros are defined: &lt;macro&gt; and &lt;macro&gt;_include.
The first one directly processes its argument using filter, while the
second one assumes its argument is wiki page name, so it reads that wiki page
content and processes it using the filter.

Macros already bundled with current release are listed below, but adding new
ones is typically as easy as adding several lines in plugin config file.

Installation
============

1. It's recommended (but not required) to install
   [popen4](http://popen4.rubyforge.org/) library first as without it plugin is
   unable to capture stderr output of external command, so it might be hard to debug
   it if things go wrong.
2. Get sources from [github](http://github.com/ndl/wiki_external_filter).
3. See [Installing a plugin](http://www.redmine.org/wiki/redmine/Plugins) on
   Redmine site.
4. Copy wiki_external_filter.yml from config folder of plugin
   directory to the config folder of your redmine installation.
5. After installation it's **strongly recommended** to go to plugin settings and
   configure caching: Administration -> Plugins -> Wiki External Filter Plugin: Configure and follow instructions. Note that RoR file-based caching suggested by default does
   not implement proper cache expiration: you should either setup a cron task to
   clean cache or do it manually from time to time.
6. To successfully use macros with argument expressions, it's necessary
   to patch wiki formatting routine so that it preserves macros arguments.

    **Redmine 1.0.2:** apply [this patch](http://www.ndl.kiev.ua/downloads/redmine-1.0.2-macros-escaping.patch) to the Redmine core and go to step 7, there's no need to patch individual wiki formatters anymore.

    **Redmine 0.9.x:** if you use Markdown Extra, switch to the following fork of [redmine_markdown_extra_formatter](http://github.com/ndl/redmine_markdown_extra_formatter) that contains all necessary changes. [This patch](http://www.ndl.kiev.ua/downloads/redmine_markdown_extra_formatter_fixes.patch.gz) is for older Markdown Extra formatter version and should not be used for new installations.

    **Note**: if you install Markdown Extra formatter - you should enable it in Administration -> Settings -> General -> Text formatting.

    If you use wiki formatter other than Markdown Extra (including default Textile formatter) **you will have to change your wiki formatter yourselves** as follows:
    * [Change MACROS_RE](http://www.redmine.org/issues/3061) regexp not to stop
      too early - in the issue description Textile wiki formatter is mentioned,
      but in fact this change should be done for whatever wiki formatter you use.
    * [Change arguments parsing](http://www.redmine.org/boards/3/topics/4987#message-9854) - again,
      should be done for whatever wiki formatter you use.
    * For some of the formatters escaping should be avoided for
      macro arguments, see how it is done for Markdown Extra wiki formatter.

    [Preliminary version of patch](http://www.redmine.org/boards/3/topics/10649#message-15222) for Textile support was made available by Yuya Nishihara, according to the author "It works but really messy" but I haven't tested it so cannot comment on it.

7. To allow passing attachments names as macros arguments Redmine core should be patched accordingly: here's [the patch for Redmine 1.0.2](http://www.ndl.kiev.ua/downloads/redmine-1.0.2-attachments.patch) and here is [the patch for Redmine 0.9.x](http://www.ndl.kiev.ua/downloads/redmine-attachments-in-macros.patch.gz).

Specific filters installation instructions are below.

Prefedined Macros
=================

plantuml
--------

[PlantUML](http://plantuml.sourceforge.net/) is a tool to render UML diagrams
from their textual representation. It's assumed that it can be invoked via
wrapper /usr/bin/plantuml, here's its example content:

    #!/bin/bash
    /usr/bin/java -Djava.io.tmpdir=/var/tmp -jar /usr/share/plantuml/lib/plantuml.jar ${@}

Result is rendered as PNG file. SVG support seems to be under development for
PlantUML but so far looks like it's still unusable.

[Gentoo ebuild](http://www.ndl.kiev.ua/downloads/plantuml-9999.ebuild.tar.gz) is attached.

Example of usage:

    {{plantuml(
    Alice -> Bob: Authentication Request
    alt successful case
      Bob -> Alice: Authentication Accepted
    else some kind of failure
      Bob -> Alice: Authentication Failure
      opt
        loop 1000 times
          Alice -> Bob: DNS Attack
        end
      end
    else Another type of failure
      Bob -> Alice: Please repeat
    end
    )}}

Rendered output:

![PlantUML output](http://www.ndl.kiev.ua/downloads/wiki_plantuml_sample.png)

graphviz
--------
[Graphviz](http://www.graphviz.org/) is a tool for graph-like structures
visualization. It's assumed that it can be called as /usr/bin/dot.

Result is rendered as SVG image or PNG fallback if SVG is not supported by your browser.

Example of usage:

    {{graphviz(
    digraph finite_state_machine {
        rankdir=LR;
        size="8,5"
        node [shape = doublecircle]; LR_0 LR_3 LR_4 LR_8;
        node [shape = circle];
        LR_0 -> LR_2 [ label = "SS(B)" ];
        LR_0 -> LR_1 [ label = "SS(S)" ];
        LR_1 -> LR_3 [ label = "S($end)" ];
        LR_2 -> LR_6 [ label = "SS(b)" ];
        LR_2 -> LR_5 [ label = "SS(a)" ];
        LR_2 -> LR_4 [ label = "S(A)" ];
        LR_5 -> LR_7 [ label = "S(b)" ];
        LR_5 -> LR_5 [ label = "S(a)" ];
        LR_6 -> LR_6 [ label = "S(b)" ];
        LR_6 -> LR_5 [ label = "S(a)" ];
        LR_7 -> LR_8 [ label = "S(b)" ];
        LR_7 -> LR_5 [ label = "S(a)" ];
        LR_8 -> LR_6 [ label = "S(b)" ];
        LR_8 -> LR_5 [ label = "S(a)" ];
    }
    )}}

Rendered output:

![Graphviz output](http://www.ndl.kiev.ua/downloads/wiki_graphviz_sample.png)

ritex
-----

Combination of [Ritex: a Ruby WebTeX to MathML converter](http://ritex.rubyforge.org/) and [SVGMath](http://www.grigoriev.ru/svgmath/) that takes WebTeX
formula specification as input and produces SVG file as output.

Both ritex and SVGMath require some patches/wrappers.

Additionally working installation of xmllint from libxml2 with configured
MathML catalog is required: for Gentoo use [this ebuild](http://bugs.gentoo.org/194501).

Gentoo ebuilds for [ritex](http://www.ndl.kiev.ua/downloads/ritex-0.3.ebuild.tar.gz) and [svgmath](http://www.ndl.kiev.ua/downloads/svgmath-0.3.3.ebuild.tar.gz) are attached.

Example of usage:

    {{ritex(
    G(y) = \left\{\array{ 1 - e^{-\lambda x} & \text{ if } y \geq 0 \\ 0 & \text{ if } y < 0 }\right.
    )}}

Rendered output:

![Ritex output](http://www.ndl.kiev.ua/downloads/wiki_ritex_sample.png)

video and video_url
-------------------

These macros use [ffmpeg](http://ffmpeg.org) to convert any supported video file to FLV format and display it on wiki using [FlowPlayer](http://www.flowplayer.org) flash player. *video* macro takes file path on server as its input, as well as attachments names from current wiki page, while *video_url* expects full URL to the video to convert & show.

Splash images for videos are generated automatically from the first frame of the video.

Multiple videos per page are supported, player instance is attached to the selected video as in [this example](http://flowplayer.org/demos/installation/multiple-players.html).

Required packages installed:

 * ffmpeg
 * RMagick
 * wget - for video_url only.

Example of usage:

    {{video(video_attachment_name.avi)}}

or

    {{video(/full/path/to/the/file/on/the/server/video.avi)}}

or

    {{video_url(http://www.example.com/video.avi)}}

Rendered output (before player is embedded by clicking on the image, using Flowplayer [video demo](http://flowplayer.org/demos/installation/index.html) file):

![Video output](http://www.ndl.kiev.ua/downloads/wiki_video_url_sample.jpg)

fortune
-------

[Fortune](http://en.wikipedia.org/wiki/Fortune_(Unix)) is a simple program
that displays a random message from a database of quotations.

Not strictly a filter on its own (as it does not require any input), but it
plays nice with external filtering approach and is fun to use, hence it's here
;-)

Example of usage:

    {{fortune}}

Rendered output:

![Fortune output](http://www.ndl.kiev.ua/downloads/wiki_fortune_sample.png)

Writing new macros
==================

New macros can easily be added via wiki_external_filter.yml config file.

Every macro may have multiple commands processing the same input - for example for **video** macro two commands are used: first one extracts thumbnail and second one converts the video.

Commands use standard Unix approach for filtering: input is fed
to the command via stdin and output is read on stdout. If command return
status is zero, content type is assumed to be of ``content_type`` specified in
config, otherwise it's assumed to be plain error text together with stderr content.

You can use ``prolog``/``epilog`` config parameters to add standard text before/after
actual macro content passed to filter.

Additionally, ``cache_seconds`` parameter specifies the number of seconds commands
output result should be cached, use zero to disable caching for this macro.

The way filter output is visualized is controlled via
app/views/wiki_external_filter/macro_*.html.erb files. The view to use is selected by  ``template`` macro option in config. The view can use all commands outputs for particular macro.

``replace_attachments`` tells plugin that it should parse the text passed to the macro and replace all occurrences of strings matching attachments names with their physical paths on disk.

Macro argument is de-escaped via CGI.unescapeHTML call prior to being fed to
filter.

Current bugs/issues
===================

1. Either Redmine core (if you use default wiki engine) or your custom wiki engine plugin requires patching to get things work. In fact, the whole
   wiki formatting design as of now seems to be quite messy.
2. SVG support is more complex it should have been if all browsers had played by the rules - currently quite some trickery with different XHTML elements/CSS tricks is used to show SVGs properly in major browsers. Of course, there's not that much that can be done for IE as it does not support SVG at all, but now at least the plugin substitutes raster fall-back image for IE if it is available.
3. For formula support, theoretically ritex alone is sufficient if you have
   MathML-capable browser, however in practice there are too many issues with
   this approach: for example Firefox (actually the onlt MathML-capable
   browser so far, it seems) requires specific DOCTYPE additions that Redmine
   currently lacks; additionally, Redmine emits text/html, while Firefox
   expects text/xml in order to parse MathML. Changing content type alone is
   not sufficient as Redmine HTML output does not pass more strict checks
   required for XML output. Hence, the double conversion (WebTeX to MathML
   and then MathML to SVG) is necessary. Once (if ever?) MathML support
   matures in other browser, possibly this can be revisited.
4. SVGs could have been embedded into HTML page directly (thus allowing to use
   redmine links there) but I'm afraid there are similar problems
   as with MathML embedding attempts.
5. RoR caching support is a mess: no way to expire old files from file-based
   cache??? Are you joking???

Additional info
===============

1. Somewhat similar plugins (although with narrower scope) are [graphviz plugin](http://github.com/tckz/redmine-wiki_graphviz_plugin) and [latex plugin](http://www.redmine.org/boards/3/topics/4987).
  Graphviz functionality is mostly covered by current version of
  wiki_external_filter. Latex is not, but only due to the fact I do not have
  latex installed nor currently have a need in that: adding macro that
  performs latex filtering should be trivial.
