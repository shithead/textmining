<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:include href="page.xsl"/> 
    <xsl:template match="/">
        <html lanf="de-de">
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
 </xsl:stylesheet>
<!-- XXX <xsl:value-of select="document('celsius.xml')/celsius/result[@value=$value]"/>
     fuer die Library
-->

