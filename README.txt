                 Redmine Wiki External Filter Plugin
                 ===================================
              Copyright (C) 2010 Alexander Tsvyashchenko,
              http://www.ndl.kiev.ua - see COPYRIGHT.txt

Overview
========

This plugin allows defining macros that process macro argument using
external filter program and render its result in Redmine wiki.

For every filter two macros are defined: <macro> and <macro>_include.
The first one directly processes its argument using filter, while the
second one assumes its argument is wiki page name, so it reads that wiki page
content and processes it using the filter.

Macros already bundled with current release are listed below, but adding new
ones is typically as easy as adding several lines in plugin config file.

Installation
============

See [Installing a plugin](http://www.redmine.org/wiki/redmine/Plugins) on
Redmine site.

Additionally, copy wiki_external_filter.yml from config folder of plugin
directory to the config folder of your redmine installation.

After installation it's **strongly recommended** to go to plugin settings and
configure caching. Note that RoR file-based caching suggested by default does
not implement proper cache expiration: you should either setup a cron task to
clean cache or do it manually from time to time.

To successfully use macros with complex argument expressions, it's necessary
to patch core Redmine components as follows:
 * [Change MACROS_RE](http://www.redmine.org/issues/3061) regexp not to stop
   too early - in the issue description textile wiki formatter is mentioned,
   but in fact this change should be done for whatever wiki formatter you use.
 * [Change arguments parsing](http://www.redmine.org/boards/3/topics/4987#message-9854) - again, should be done for whatever wiki formatter you use.
 * Additionally, for some of the formatters escaping should be avoided for
   macro arguments.

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

graphviz
--------
[Graphviz](http://www.graphviz.org/) is a tool for graph-like structures
visualization. It's assumed that it can be called as /usr/bin/dot.

Result is rendered as SVG file.

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

ritex
-----

Combination of [Ritex: a Ruby WebTeX to MathML converter](http://ritex.rubyforge.org/) and [SVGMath](http://www.grigoriev.ru/svgmath/) that takes WebTeX
formula specification as input and produces SVG file as output.

Both ritex and SVGMath require some patches/wrappers.

Additionally working installation of xmllint from libxml2 with configured
MathML catalog is required: for Gentoo use [this ebuild](http://bugs.gentoo.org/194501).

Example of usage:

    {{ritex(
    G(y) = \left\{\array{ 1 - e^{-\lambda x} & \text{ if } y \geq 0 \\ 0 & \text{ if } y < 0 }\right.
    )}}

fortune
-------

[Fortune](http://en.wikipedia.org/wiki/Fortune_(Unix)) is a simple program
that displays a random message from a database of quotations.

Not strictly a filter on its own (as it does not require any input), but it
plays nice with external filtering approach and is fun to use, hence it's here
;-)

Example of usage:

    {{fortune}}

Writing new macros
==================

New macros can easily be added via wiki_external_filter.yml config file.

Wiki external filter uses standard Unix approach for filtering: input is fed
to the command via stdin and output is read on stdout. If command return
status is zero, content type is assumed to be of content_type specified in
config, otherwise it's assumed it's plain error text.

You can use prolog/epilog config parameters to add standard text before/after
actual macro content passed to filter.

Additionally, cache_seconds parameter specifies the number of seconds command
output result should be cached, use zero to disable caching for this
particular command.

Macro argument is de-escaped via CGI.unescapeHTML call prior to being fed to
filter.

The way filter output is visualized is controlled via
app/views/wiki_external_filter/macro_*.html.erb files.

By default all 'image/*' content types are rendered as <img>, 'text/plain'
is included in resulting HTML page with escaping, all '*/*xml*'
and '*/*html*' content types are included directly into output page without
escaping, all other content types are embedded as <object>.

Current bugs/issues
===================

1. Redmine core requires patching to get things work. In fact, the whole
   wiki formatting design as of now seems to be quite messy.
2. FireFox has broken implementation of SVG rendering: <img> tag for SVG
   inclusion does not work: see the [related bug](https://bugzilla.mozilla.org/show_bug.cgi?id=276431) dated back to 2004 (sic!).
   WebKit browsers, on the other hand, are too fragile with <object> SVG
   embedding, having problems with resulting image size.
   Considering I do not use FireFox but use WebKit-based browsers - guess
   which route I've chosen ;-)
   If you insist on making it work for FireFox (and breaking things for
   WebKit-based browsers) - copy <object> embedding code in the views
   templates under the `when /image\/svg\+xml/ then` clause (put it before
   generic 'image' case).
   Alternatively, you can use some JavaScript-based trickery to use different
   embedding ways depending on browser version.
   Of course, IE does not support SVG at all, but who really uses it these
   days anyway? ;-)
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
