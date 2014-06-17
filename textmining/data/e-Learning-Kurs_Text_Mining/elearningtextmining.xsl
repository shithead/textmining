<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
            <html>
            <head>
                <title> <xsl:value-of select="course/meta/title"/> </title>
                <link href="layouts/elearningtextmining.css" rel="stylesheet" type="text/css" />
                <script type="text/javascript">
                    function unhide(divID) {
                    var item = document.getElementById(divID);
                    if (item) {
                    item.className=(item.className=='hidden')?'unhidden':'hidden';
                    }
                    }
                </script> 
            </head>
            <body>
                <!-- OPEN GLOBEL DIV -->
                <div id="site_wrapper" class="site-wrap">
                    <div id="header_wrapper" class="header-wrap">
                        <div id="header" class="header  cw">
                            <xsl:value-of select="course/module/meta/title"/>
                        </div>
                    </div>
                    <!-- OPEN SITE DIV for navigation and pages -->
                    <div class="site-nc-wrapper">
                        <!-- OPEN NAVI DIV -->
                        <div id="navi-sidebar_wrapper" class="navi-sidebar-wrap">
                            <div id="navi-sidebar" class="navi-sidebar-menu">
                                <!-- OPEN NAVI LISTE  get all headlines and build hierach list elements -->
                                <ul class="navi-sidebar-ul" id="navi-sidebar-menu__list">
                                    <xsl:for-each select="course/module/chapter/page">
                                        <xsl:if test="h1">
                                            <li> <xsl:value-of select="h1"/> </li>
                                        </xsl:if>
                                        <ul>
                                            <xsl:if test="h2">
                                                <li> <xsl:value-of select="h2"/> </li>
                                            </xsl:if>
                                            <xsl:if test="h3">
                                                <ul>
                                                    <li> <xsl:value-of select="h3"/> </li>
                                                </ul>
                                            </xsl:if>
                                        </ul>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </div>
                        <!-- BUILD PAGES -->
                        <xsl:for-each select="course/module/chapter">
                            <xsl:apply-templates select="current()"/>
                        </xsl:for-each>
                    </div>
                    <!-- FOOTER -->
                    <div id="footer_wrapper" class="footer-wrap">
                        <span>Author:
                            <xsl:for-each select="course/module/meta">
                                <xsl:apply-templates select="authors"/>
                            </xsl:for-each>
                        </span>
                        <span>Erstellt:
                            <xsl:value-of select="course/module/meta/date"/>
                        </span>
                    </div>
                </div>
            </body>
        </html>

    </xsl:template>
    <!--
    <!ELEMENT a ( #PCDATA ) >
    <!ATTLIST a href CDATA #REQUIRED >
    -->
    <xsl:template match="a">
        <a href="{@href}"><xsl:value-of select="text()"/></a>
    </xsl:template>
    <!--
    <!ELEMENT author ( #PCDATA ) >
    -->
    <xsl:template match="author">
        <xsl:value-of select="text()"/>
    </xsl:template>
    <!--
    <!ELEMENT authors ( author+ ) >
    -->
    <xsl:template match="authors">
        <xsl:apply-templates select="author"/>
        <!-- wenn noch mehr als 2 AuthorInnen folgen ein ", " setzen -->
        <xsl:if test="position() &lt; last()-1">
            <xsl:text>, </xsl:text>
        </xsl:if>
        <!-- Wenn der/die vorletzte AuthorIn ist ", and " setzen -->
        <xsl:if test="position()=last()-1">
            <xsl:text>, and </xsl:text>
        </xsl:if>
        <!-- Wenn letzte(r) AuthorIn ist " " setzen -->
        <xsl:if test="position()=last()">
            <xsl:text> </xsl:text>
        </xsl:if>
    </xsl:template>
    <!--
    <!ELEMENT bib ( #PCDATA | person )* >
    <!ATTLIST bib id CDATA #REQUIRED >
    <!ATTLIST bib page CDATA #IMPLIED>
    -->
    <xsl:template match="bib">
        <bib class="message" id="{@id}" page="{@page}">
            <span>
                <a class="css-truncate css-truncate-target" title="Hier steht der Bibliotheksinhalt">
                    <xsl:apply-templates select="text() | person"/>
                </a>
            </span>
        </bib>
    </xsl:template>
    <!--
    <!ELEMENT chapter ( page+ ) >
    <!ATTLIST chapter id NMTOKEN #REQUIRED >
    <!ATTLIST chapter type NMTOKEN #IMPLIED >
    -->
    <xsl:template match="chapter">
        <div id="chapter_wrapper_{@id}" class="chapter-wrap" type="{@type}">
            <xsl:apply-templates select="page"/>
        </div>
    </xsl:template>
    <!--
    <!ELEMENT course ( meta, module ) >
    -->
    <xsl:template match="course">
        <xsl:apply-templates select="meta | module"/>
    </xsl:template>
    <!--
    <!ELEMENT date ( #PCDATA ) >
    -->
    <xsl:template match="date">
        <xsl:value-of select="text()"/>
    </xsl:template>
    <!--
    <!ELEMENT details ( #PCDATA | a | bib | emph | foreign | img | kursiv | person | term )* >
    <!ATTLIST details id ID #REQUIRED >
    -->
    <xsl:template match="details">
        <a href="javascript:unhide('div_details_{@id}');">Details</a> 
        <div id="div_details_{@id}">
            <p align="justify">
                <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | term"/>
            </p>
        </div>
    </xsl:template>
    <!--
    <!ELEMENT emph ( #PCDATA ) >
    -->
    <xsl:template match="emph">
        <em>
            <xsl:value-of select="text()"/>
        </em>
    </xsl:template>
    <!--
    <!ELEMENT example ( p | ul | details )* >
    -->
    <xsl:template match="example">
        <div id="div_example">
            <xsl:apply-templates select="p | ul"/>
        </div>
    </xsl:template>
    <!--
    <!ELEMENT foreign ( #PCDATA ) >
    -->
    <xsl:template match="foreign">
        <xsl:value-of select="text()"/>
    </xsl:template>
    <!--
    <!ELEMENT h1 ( #PCDATA | term )* >
    -->
    <xsl:template match="h1">
        <h1>
            <xsl:apply-templates select="text() | term"/>
        </h1>
    </xsl:template>
    <!--
    <!ELEMENT h2 ( #PCDATA | term )* >
    -->
    <xsl:template match="h2">
        <h2>
            <xsl:apply-templates select="text() | term"/>
        </h2>
    </xsl:template>
    <!--
    <!ELEMENT h3 ( #PCDATA | term )* >
    -->
    <xsl:template match="h3">
        <h3>
            <xsl:apply-templates select="text() | term"/>
        </h3>
    </xsl:template>
    <!--
    <!ELEMENT img EMPTY >
    <!ATTLIST img src CDATA #REQUIRED >
    -->
    <xsl:template match="img">
        <img src="{@src}"></img>
    </xsl:template>
    <!--
    <!ELEMENT kursiv ( #PCDATA ) >
    -->
    <xsl:template match="kursiv">
        <i>
            <xsl:value-of select="text()"/>
        </i>
    </xsl:template>
    <!--
    <!ELEMENT li ( #PCDATA | a | bib | emph | foreign | img | kursiv | person | term )* >
    -->
    <xsl:template match="li">
        <li>
            <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | term"/>
        </li>
    </xsl:template>
    <!--
    <!ELEMENT meta ( title, version, date, authors ) >
    -->
    <xsl:template match="meta">
        <xsl:apply-templates select="title | version | date | authors"/>
    </xsl:template>
    <!--
    <!ELEMENT module ( chapter | meta )* >
    <!ATTLIST module id NMTOKEN #REQUIRED >
    -->
     <xsl:template match="module">
         <xsl:apply-templates select="chapter | meta"/>
     </xsl:template>
     <!--
    <!ELEMENT p ( #PCDATA | a | bib | emph | foreign | img | kursiv | person | term )* >
    <!ATTLIST p type NMTOKEN #IMPLIED >
    -->
    <xsl:template match="p">
        <xsl:choose>
            <xsl:when test="@type='example'">
            </xsl:when>
            <xsl:when test="@type='quota'">
                <p align="justify">
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | term"/>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | term"/>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT page ( h1 | h2 | h3 | p | ul | details | example)* >
    -->
    <xsl:template match="page">
        <div id="page_header" class="page-header">
            <xsl:if test="h1">
                <h1> <xsl:value-of select="h1"/> </h1>
            </xsl:if>
            <xsl:if test="h2">
                <h2> <xsl:value-of select="h2"/> </h2>
            </xsl:if>
            <xsl:if test="h3">
                <h3> <xsl:value-of select="h3"/> </h3>
            </xsl:if>
        </div>
        <div id="page_body" class="page-body">
            <xsl:apply-templates select="p | ul | details | example"/>
        </div>
    </xsl:template>
    <!--
    <!ELEMENT person ( #PCDATA )* >
    <!ATTLIST person name CDATA #REQUIRED >
    -->
    <xsl:template match="person">
        <person name="{@name}">
            <xsl:value-of select="text()"/>
        </person>
    </xsl:template>
    <!--
    <!ELEMENT term ( #PCDATA | emph | foreign | kursiv ) >
    -->
    <xsl:template match="term">
        <xsl:apply-templates select="text() | emph | foreign | kursiv"/>
    </xsl:template>
    <!--
    <!ELEMENT title ( #PCDATA ) >
    -->
    <xsl:template match="title">
        <title>
            <xsl:value-of select="text()"/>
        </title>
    </xsl:template>
    <!--
    <!ELEMENT ul ( li+ ) >
    -->
    <xsl:template match="ul">
        <ul>
            <xsl:apply-templates select="li"/>
        </ul>
    </xsl:template>
    <!--
    <!ELEMENT version ( #PCDATA ) >
    -->
    <xsl:template match="version">
        <xsl:value-of select="text()"/>
    </xsl:template>
</xsl:stylesheet>

<!-- XXX <xsl:value-of select="document('celsius.xml')/celsius/result[@value=$value]"/>
     fuer die Library
-->

