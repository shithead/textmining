<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
            <html>
            <head>
                <title> <xsl:value-of select="course/meta/title"/> </title>
                <link href="layouts/elearningtextmining.css" rel="stylesheet" type="text/css" />
                <script type="text/javascript">
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
                                <ol class="navi-sidebar-ol" id="navi-sidebar-menu__list">
                                    <xsl:for-each select="course/module/chapter/page">
                                        <xsl:if test="h1">
                                            <li> <xsl:value-of select="h1"/> </li>
                                        </xsl:if>
                                        <ol>
                                            <xsl:if test="h2">
                                                <li> <xsl:value-of select="h2"/> </li>
                                            </xsl:if>
                                            <xsl:if test="h3">
                                                <ol>
                                                    <li> <xsl:value-of select="h3"/> </li>
                                                </ol>
                                            </xsl:if>
                                        </ol>
                                    </xsl:for-each>
                                </ol>
                            </div>
                        </div>
                        <!-- BUILD PAGES -->
                        <xsl:for-each select="course/module/chapter">
                            <xsl:apply-templates select="current()"/>
                        </xsl:for-each>
                    </div>
                    <!-- FOOTER -->
                    <footer id="footer_wrapper" class="footer-wrap">
                        <span>Author:
                            <xsl:for-each select="course/module/meta">
                                <xsl:apply-templates select="authors"/>
                            </xsl:for-each>
                        </span>
                        <span>Erstellt:
                            <xsl:value-of select="course/module/meta/date"/>
                        </span>
                    </footer>
                </div>
            </body>
        </html>
    </xsl:template>

    <xsl:template match="action">
        <xsl:apply-templates select="text | url"/>
    </xsl:template>

    <xsl:template match="answer">
        <xsl:choose>
            <xsl:when test="@type='multi'">
                <xsl:apply-templates select="option"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="option"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="author">
        <xsl:value-of select="text()"/>
    </xsl:template>

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

    <xsl:template match="bib">
        <bib class="message" id="{@id}" page="{@page}">
            <span>
                <a class="css-truncate css-truncate-target" title="Hier steht der Bibliotheksinhalt">
                    <xsl:apply-templates select="text() | person"/>
                </a>
            </span>
        </bib>
    </xsl:template>

    <xsl:template match="chapter">
        <div id="chapter_wrapper_{@id}" class="chapter-wrap" type="{@type}">
            <xsl:apply-templates select="page"/>
        </div>
    </xsl:template>

    <xsl:template match="check">
        <xsl:apply-templates select="question | answer"/>
    </xsl:template>

    <xsl:template match="course">
        <xsl:apply-templates select="meta | module"/>
    </xsl:template>

    <xsl:template match="date">
        <xsl:value-of select="text()"/>
    </xsl:template>

    <!-- TODO wird im html nicht erstellt -->
    <xsl:template match="detail">
        <span class="hidden">
            <xsl:apply-templates select="text()"/>
        </span>
    </xsl:template>

    <xsl:template match="emph">
        <b>
            <xsl:value-of select="text()"/>
        </b>
    </xsl:template>

    <xsl:template match="foreign">
        <xsl:value-of select="text()"/>
    </xsl:template>

    <xsl:template match="h1">
        <h1>
            <xsl:apply-templates select="text() | term"/>
        </h1>
    </xsl:template>

    <xsl:template match="h2">
        <h2>
            <xsl:apply-templates select="text() | term"/>
        </h2>
    </xsl:template>

    <xsl:template match="h3">
        <h3>
            <xsl:apply-templates select="text() | term"/>
        </h3>
    </xsl:template>

    <xsl:template match="img">
        <img src="{@src}"></img>
    </xsl:template>

    <xsl:template match="kursiv">
        <i>
            <xsl:value-of select="text()"/>
        </i>
    </xsl:template>

    <xsl:template match="li">
        <xsl:choose>
            <xsl:when test="@type='detail'">
                <li class="hidden">
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | term"/>
                </li>
            </xsl:when>
            <xsl:otherwise>
                <li>
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | term"/>
                </li>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="meta">
        <xsl:apply-templates select="title | version | date | authors"/>
    </xsl:template>

    <xsl:template match="module">
        <xsl:apply-templates select="chapter | meta"/>
    </xsl:template>

    <xsl:template match="option">
        <xsl:apply-templates select="text | action"/>
    </xsl:template>

    <xsl:template match="p">
        <xsl:choose>
            <xsl:when test="@type='quote'">
                <p align="justify">
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                </p>
            </xsl:when>
            <xsl:when test="@type='detail'">
                <p class="hidden">
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                </p>
            </xsl:when>
            <xsl:when test="@type='example'">
                <p class="example">
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                </p>
            </xsl:when>
            <xsl:otherwise>
                <p>
                    <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                </p>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

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
            <xsl:apply-templates select="p | list"/>
        </div>
    </xsl:template>

    <xsl:template match="person">
        <person name="{@name}">
            <xsl:value-of select="text()"/>
        </person>
    </xsl:template>

    <xsl:template match="term">
        <xsl:apply-templates select="text() | emph | foreign | kursiv"/>
    </xsl:template>

    <xsl:template match="text">
        <xsl:apply-templates select="text() | list | p | term"/>
    </xsl:template>

    <xsl:template match="title">
        <title>
            <xsl:value-of select="text()"/>
        </title>
    </xsl:template>

    <xsl:template match="list">
        <xsl:choose>
            <xsl:when test="@type='ordered'">
                <ol>
                    <xsl:apply-templates select="li"/>
                </ol>
            </xsl:when>
            <xsl:otherwise>
                <ul>
                    <xsl:apply-templates select="li"/>
                </ul>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <xsl:template match="quantity">
        <xsl:value-of select="text()"/>
    </xsl:template>

    <xsl:template match="question">
        <xsl:apply-templates select="text"/>
    </xsl:template>

    <xsl:template match="url">
        <a href="{@href}"><xsl:value-of select="text()"/></a>
    </xsl:template>

    <xsl:template match="version">
        <xsl:value-of select="text()"/>
    </xsl:template>
</xsl:stylesheet>

<!-- XXX <xsl:value-of select="document('celsius.xml')/celsius/result[@value=$value]"/>
     fuer die Library
-->

