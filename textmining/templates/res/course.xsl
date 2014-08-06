<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:template match="/">
        <html lanf="de">
            <head>
                <meta http-equiv="refresh" content="5" />
                <meta http-equiv="content-type" content="text/html; charset=UTF-8"/>
                <meta charset="utf-8"/>
                <title> <xsl:value-of select="course/meta/title"/> </title>
                <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1"/>
                <link href="layouts/css/bootstrap.min.css" rel="stylesheet"/>
                <link href="layouts/css/bootstrap-glyphicons.css" type="text/css" rel="stylesheet"/>
                <!--[if lt IE 9]>
                    <script src="//html5shim.googlecode.com/svn/trunk/html5.js"></script>
                <![endif]-->
                <style type="text/css">
                    body {
                    padding-top: 50px;
                    overflow: hidden;
                    }
                    #wrapper {
                    min-height: 100%;
                    height: 100%;
                    width: 100%;
                    position: absolute;
                    top: 0px;
                    left: 0;
                    display: inline-block;
                    }
                    #main-wrapper {
                    height: 100%;
                    overflow-y: auto;
                    padding: 50px 0 0px 0;
                    }
                    #main {
                    position: relative;
                    height: 100%;
                    overflow-y: auto;
                    padding: 0 15px;
                    }
                    #sidebar-wrapper {
                    height: 100%;
                    padding: 50px 0 0px 0;
                    position: fixed;
                    border-right: 1px solid gray;
                    }
                    #sidebar {
                    position: relative;
                    height: 100%;
                    overflow-y: auto;
                    }
                    #sidebar .list-group-item {
                    border-radius: 0;
                    border-left: 0;
                    border-right: 0;
                    border-top: 0;
                    }
                    @media (max-width: 992px) {
                    body {
                    padding-top: 0px;
                    }
                    }
                    @media (min-width: 992px) {
                    #main-wrapper {
                    float:right;
                    }
                    }
                    @media (max-width: 992px) {
                    #main-wrapper {
                    padding-top: 0px;
                    }
                    }
                    @media (max-width: 992px) {
                    #sidebar-wrapper {
                    position: static;
                    height:auto;
                    max-height: 300px;
                    border-right:0;
                    }
                    }
                </style>
            </head>
            <body>
                <header class="navbar navbar-default navbar-fixed-top">
                    <div class="navbar-inner">
                        <button class="navbar-toggle collapsed"  data-target=".nav-collapse" data-toggle="collapse" type="button">
                            <i class="icon-reorder"></i>
                        </button>
                        <a class="navbar-brand" href="#"><xsl:value-of select="course/module/meta/title"/></a>
                    </div>
                    <nav class="navbar-collapse collapse">
                        <ul class="nav navbar-nav">
                            <li class="active">
                                <a href="#">Home</a>
                            </li>
                            <li class="divider-vertical"></li>
                            <li>
                                <a href="#about">About</a>
                            </li>
                            <li>
                                <a href="#contact">Contact</a>
                            </li>

                        </ul>
                    </nav>
            </header>
                <div id="wrapper">
                    <div id="sidebar-wrapper" class="col-md-1">
                        <div id="sidebar">
                            <ul class="nav list-group">
                                <xsl:for-each select="course/module/chapter">
                                    <xsl:variable name="chapter_id" select="@id" /> 
                                    <xsl:for-each select="page">
                                        <xsl:if test="h1">
                                            <li>
                                                <a class="list-group-item" href="#chapter_wrapper_{$chapter_id}">
                                                    <xsl:value-of select="h1"/>
                                                </a>
                                            </li>
                                        </xsl:if>
                                    </xsl:for-each>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </div>
                </div>
                <div id="main-wrapper" class="col-md-11 pull-right">
                    <div id="main">
                        <!-- BUILD PAGES -->
                        <xsl:for-each select="course/module/chapter">
                            <xsl:apply-templates select="current()"/>
                        </xsl:for-each>
                        <!-- FOOTER -->
                        <footer>
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
                </div>


                 <!-- Le javascript
                 ================================================== -->
                 <!-- Placed at the end of the document so the pages load faster -->
                 <script src="layouts/js/jquery.js"></script>
                 <script src="layouts/js/bootstrap.js"></script>
                 <script src="layouts/js/bootstrap.min.js"></script>
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
         <time><xsl:value-of select="text()"/></time>
     </xsl:template>

     <!-- XXX wird im html nicht erstellt -->
     <xsl:template match="detail">
         <details>
             <xsl:apply-templates select="text()"/>
         </details>
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
                 <p><cite>
                         <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                 </cite></p>
             </xsl:when>
             <xsl:when test="@type='detail'">
                 <details><p>
                         <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                 </p></details>
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
         <div class="page-header">
             <xsl:if test="h2">
                 <h2> <xsl:value-of select="h2"/> </h2>
             </xsl:if>
             <xsl:if test="h3">
                 <h3> <xsl:value-of select="h3"/> </h3>
             </xsl:if>
             <xsl:apply-templates select="p | list"/>
         </div>
     </xsl:template>

     <xsl:template match="person">
         <person name="{@name}">
             <xsl:value-of select="text()"/>
         </person>
     </xsl:template>

     <xsl:template match="term">
         <dfn><xsl:apply-templates select="text() | emph | foreign | kursiv"/></dfn>
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

