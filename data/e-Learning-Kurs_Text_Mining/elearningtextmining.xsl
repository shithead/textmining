<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <html>
            <head>
                <title> <xsl:value-of select="course/meta/title"/> </title>
            </head>
            <body>
                <div class="site-wrapper">
                    <div id="header_wrapper" class="header-wrap">
                        <div id="header" class="header  cw">
                            <span> <xsl:value-of select="course/module/meta/title"/> </span>
                        </div>
                    </div>
                    <div class="site-nc-wrapper">
                        <div id="navi-sidebar_wrapper" class="navi-sidebar-wrap">
                            <div id="navi-sidebar" class="navi-sidebar-menu">
                                <ul class="nav-sidebar-menu__list">
                                    <!--<li class="nav-sidebar-menu__heading">
                                        <span>Seiten</span>
                                    </li> -->
                                    <xsl:for-each select="course/module/chapter/page">
                                        <ul>
                                            <xsl:if test="h1">
                                                <li> <xsl:value-of select="h1"/> </li>
                                            </xsl:if>
                                            <ul>
                                                <xsl:if test="h2">
                                                    <li> <xsl:value-of select="h2"/> </li>
                                                </xsl:if>
                                                <ul>
                                                    <xsl:if test="h3">
                                                        <li> <xsl:value-of select="h3"/> </li>
                                                    </xsl:if>
                                                    <ul>
                                                        <xsl:if test="h4">
                                                            <li> <xsl:value-of select="h4"/> </li>
                                                        </xsl:if>
                                                        <ul>
                                                            <xsl:if test="h5">
                                                                <li> <xsl:value-of select="h5"/> </li>
                                                            </xsl:if>
                                                        </ul>
                                                    </ul>
                                                </ul>
                                            </ul>
                                        </ul>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </div>
                        <div id="page-content_wrapper" class="page-content-wrap">
                            <xsl:for-each select="course/module/chapter/page">
                                <div id="page_header" class="page-header">
                                    <!-- TODO headlines grammatik erzeugen -->
                                    <xsl:if test="h1">
                                        <h1> <xsl:value-of select="h1"/> </h1>
                                    </xsl:if>
                                    <xsl:if test="h2">
                                        <h2> <xsl:value-of select="h2"/> </h2>
                                    </xsl:if>
                                    <xsl:if test="h3">
                                        <h3> <xsl:value-of select="h3"/> </h3>
                                    </xsl:if>
                                    <xsl:if test="h4">
                                        <h4> <xsl:value-of select="h4"/> </h4>
                                    </xsl:if>
                                    <xsl:if test="h5">
                                        <h5> <xsl:value-of select="h5"/> </h5>
                                    </xsl:if>
                                </div>
                                <div id="page_body" class="page-body">
                                             <xsl:apply-templates select="(a|p|ul)"/>
                                        </div>
                            </xsl:for-each>
                        </div>
                    </div>
                    <div id="footer_wrapper" class="footer-wrap">
                        <span>Author:
                            <xsl:for-each select="course/module/meta/authors">
                                <xsl:value-of select="author"/>,
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
    <xsl:template match="a">
        <a href="{@href}"><xsl:value-of select="current()"/></a>
    </xsl:template>
    <xsl:template match="bib">
            <xsl:value-of select="current()"/>
    </xsl:template>
    <xsl:template match="emph">
        <b>
            <xsl:value-of select="current()"/>
        </b>
    </xsl:template>
    <xsl:template match="img">
        <img src="{@src}"><xsl:value-of select="current()"/></img>
    </xsl:template>
            <!-- kann man das hier vielleicht noch unterteilen in
                 *  mit nodes
                 *  mit attribute
                 *  ohne alles-->
    <xsl:template match="p">
            <p align="justify">
                <xsl:apply-templates select="child:node()"/>
            </p>
    </xsl:template>
    <xsl:template match="person">
            <xsl:value-of select="current()"/>
    </xsl:template>
    <xsl:template match="term">
            <xsl:apply-templates select="foreign"/>
    </xsl:template>
    <xsl:template match="ul">
        <ul>
            <xsl:for-each select="li">
                <li><xsl:value-of select="current()"/> </li>
            </xsl:for-each>
        </ul>
    </xsl:template>
</xsl:stylesheet>

<!-- XXX <xsl:value-of select="document('celsius.xml')/celsius/result[@value=$value]"/>
     fuer die Libary
-->
