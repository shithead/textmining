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
                                </div>
                                <div id="page_body" class="page-body">
                                    <xsl:apply-templates select="(a|p|ul)"/>
                                </div>
                            </xsl:for-each>
                        </div>
                    </div>
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
        <xsl:choose>
            <xsl:when test="@href">
                <a href="{@href}"><xsl:value-of select="current()"/></a>
            </xsl:when>
            <xsl:otherwise>
                <a><xsl:value-of select="current()"/></a>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT author ( #PCDATA ) >
    -->
    <xsl:template match="author">
        <xsl:value-of select="current()"/>
    </xsl:template>
    <!--
    <!ELEMENT authors ( author+ ) >
    -->
    <xsl:template match="authors">
        <xsl:apply-templates select="author"/>
    </xsl:template>
    <!--
    <!ELEMENT bib ( #PCDATA | person )* >
    <!ATTLIST bib id CDATA #REQUIRED >
    <!ATTLIST bib page CDATA >
    -->
    <xsl:template match="bib">
        <xsl:choose>
            <xsl:when test="@id">
                <xsl:value-of select="current()"/>
            </xsl:when>
            <xsl:when test="@page">
                <xsl:value-of select="current()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="current()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT chapter ( page+ ) >
    <!ATTLIST chapter id NMTOKEN #REQUIRED >
    <!ATTLIST chapter type NMTOKEN #IMPLIED >
    -->
    <xsl:template match="chapter">
        <xsl:choose>
            <xsl:when test="@id">
                <xsl:value-of select="current()"/>
            </xsl:when>
            <xsl:when test="@type">
                <xsl:value-of select="current()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="page"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT course ( meta, module ) >
    -->
    <xsl:template match="course">
        <xsl:apply-templates select="(meta|module)"/>
    </xsl:template>
    <!--
    <!ELEMENT date ( #PCDATA ) >
    -->
    <xsl:template match="date">
        <xsl:value-of select="current()"/>
    </xsl:template>
    <!--
    <!ELEMENT emph ( #PCDATA ) >
    -->
    <xsl:template match="emph">
        <em>
            <xsl:value-of select="current()"/>
        </em>
    </xsl:template>
    <!--
    <!ELEMENT foreign ( #PCDATA ) >
    -->
    <xsl:template match="foreign">
        <xsl:value-of select="current()"/>
    </xsl:template>
    <!--
    <!ELEMENT h1 ( #PCDATA | term )* >
    -->
    <xsl:template match="h1">
        <xsl:choose>
            <xsl:when test="term">
                <xsl:apply-templates select="term"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="current()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT h2 ( #PCDATA | term )* >
    -->
    <xsl:template match="h2">
        <xsl:choose>
            <xsl:when test="term">
                <xsl:apply-templates select="term"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="current()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT h3 ( #PCDATA | term )* >
    -->
    <xsl:template match="h3">
        <xsl:choose>
            <xsl:when test="term">
                <xsl:apply-templates select="term"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="current()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT img EMPTY >
    <!ATTLIST img src CDATA #REQUIRED >
    -->
    <xsl:template match="img">
        <xsl:choose>
            <xsl:when test="@src">
                <img src="{@src}"><xsl:value-of select="current()"/></img>
            </xsl:when>
            <xsl:otherwise>
                <img></img>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT kursiv ( #PCDATA ) >
    -->
    <xsl:template match="kursiv">
        <i>
            <xsl:value-of select="current()"/>
        </i>
    </xsl:template>
    <!--
    <!ELEMENT li ( #PCDATA | a | bib | emph | foreign | img | kursiv | person | term )* >
    -->
    <xsl:template match="li">
        <li>
            <xsl:choose>
                <xsl:when test="a">
                    <xsl:apply-templates select="a"/>
                </xsl:when>
                <xsl:when test="bib">
                    <xsl:apply-templates select="bib"/>
                </xsl:when>
                <xsl:when test="emph">
                    <xsl:apply-templates select="emph"/>
                </xsl:when>
                <xsl:when test="foreign">
                    <xsl:apply-templates select="foreign"/>
                </xsl:when>
                <xsl:when test="img">
                    <xsl:apply-templates select="img"/>
                </xsl:when>
                <xsl:when test="kursiv">
                    <xsl:apply-templates select="kursiv"/>
                </xsl:when>
                <xsl:when test="person">
                    <xsl:apply-templates select="person"/>
                </xsl:when>
                <xsl:when test="term">
                    <xsl:apply-templates select="term"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="current()"/>
                </xsl:otherwise>
            </xsl:choose>
        </li>
    </xsl:template>
    <!--
    <!ELEMENT meta ( title, version, date, authors ) >
    -->
    <xsl:template match="meta">
        <xsl:choose>
            <xsl:when test="authors">
                <xsl:apply-templates select="authors"/>
            </xsl:when>
            <xsl:when test="date">
                <xsl:apply-templates select="date"/>
            </xsl:when>
            <xsl:when test="title">
                <xsl:apply-templates select="title"/>
            </xsl:when>
            <xsl:when test="version">
                <xsl:apply-templates select="version"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT module ( chapter | meta )* >
    <!ATTLIST module id NMTOKEN #REQUIRED >
    -->
     <xsl:template match="module">
         <xsl:choose>
             <xsl:when test="chapter">
                 <xsl:apply-templates select="chapter"/>
             </xsl:when>
             <xsl:when test="meta">
                 <xsl:apply-templates select="meta"/>
             </xsl:when>
             <xsl:when test="@id">
                 <xsl:value-of select="current()"/>
             </xsl:when>
         </xsl:choose>
     </xsl:template>
     <!--
    <!ELEMENT p ( #PCDATA | a | bib | emph | foreign | img | kursiv | person | term )* >
    <!ATTLIST p type NMTOKEN #IMPLIED >
    -->
    <xsl:template match="p">
        <p align="justify">
            <xsl:choose>
                <xsl:when test="a">
                    <xsl:apply-templates select="a"/>
                </xsl:when>
                <xsl:when test="bib">
                    <xsl:apply-templates select="bib"/>
                </xsl:when>
                <xsl:when test="emph">
                    <xsl:apply-templates select="emph"/>
                </xsl:when>
                <xsl:when test="foreign">
                    <xsl:apply-templates select="foreign"/>
                </xsl:when>
                <xsl:when test="img">
                    <xsl:apply-templates select="img"/>
                </xsl:when>
                <xsl:when test="kursiv">
                    <xsl:apply-templates select="kursiv"/>
                </xsl:when>
                <xsl:when test="person">
                    <xsl:apply-templates select="person"/>
                </xsl:when>
                <xsl:when test="term">
                    <xsl:apply-templates select="term"/>
                </xsl:when>
                <xsl:when test="@type">
                    <xsl:value-of select="current()"/>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:value-of select="current()"/>
                </xsl:otherwise>
            </xsl:choose>
        </p>
    </xsl:template>
    <!--
    <!ELEMENT page ( h1 | h2 | h3 | p | ul )* >
    -->
    <xsl:template match="page">
        <xsl:choose>
            <xsl:when test="h1">
                <xsl:apply-templates select="h1"/>
            </xsl:when>
            <xsl:when test="h2">
                <xsl:apply-templates select="h2"/>
            </xsl:when>
            <xsl:when test="h3">
                <xsl:apply-templates select="h3"/>
            </xsl:when>
            <xsl:when test="p">
                <xsl:apply-templates select="p"/>
            </xsl:when>
            <xsl:when test="ul">
                <xsl:apply-templates select="ul"/>
            </xsl:when>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT person ( #PCDATA )* >
    <!ATTLIST person name CDATA #REQUIRED >
    -->
    <xsl:template match="person">
        <xsl:choose>
            <xsl:when test="@name">
                <xsl:value-of select="current()"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="current()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT term ( #PCDATA | emph | foreign | kursiv ) >
    -->
    <xsl:template match="term">
        <xsl:choose>
            <xsl:when test="emph">
                <xsl:apply-templates select="emph"/>
            </xsl:when>
            <xsl:when test="foreign">
                <xsl:apply-templates select="foreign"/>
            </xsl:when>
            <xsl:when test="kursiv">
                <xsl:apply-templates select="kursiv"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="current()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!--
    <!ELEMENT title ( #PCDATA ) >
    -->
    <xsl:template match="title">
        <title>
            <xsl:value-of select="current()"/>
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
        <xsl:value-of select="current()"/>
    </xsl:template>
</xsl:stylesheet>

<!-- XXX <xsl:value-of select="document('celsius.xml')/celsius/result[@value=$value]"/>
     fuer die Libary
-->
