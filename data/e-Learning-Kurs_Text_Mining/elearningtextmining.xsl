<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
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
                                    <span> <xsl:value-of select="h1"/> </span>
                                </div>
                                <div id="page_body" class="page-body">

                                    <p align="justify"> <xsl:value-of select="p"/></p>
                                    <xsl:for-each select="ul">
                                        <ul>
                                            <xsl:for-each select="li">
                                                <li><xsl:value-of select=""/> </li>
                                    </xsl:for-each>
                                        </ul>
                                    </xsl:for-each>

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
</xsl:stylesheet>

<!-- <xsl:value-of select="document('celsius.xml')/celsius/result[@value=$value]"/> 
     fuer die Libary
-->
