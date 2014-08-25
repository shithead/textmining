<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>

     <xsl:template match="action">
         <xsl:apply-templates select="text | url"/>
     </xsl:template>

     <xsl:template match="answer">
         <div class="well bs-component">
             <form class="form-horizontal">
                 <xsl:choose>
                     <xsl:when test="@type='multi'">
                         <fieldset>
                             <div class="form-group">
                                 <label class="col-lg-2 control-label" for="select">Selects</label>
                                 <div class="col-lg-10">
                                     <select id="select" class="form-control">
                                         <option><xsl:apply-templates select="option"/></option>
                                     </select>

                                 </div>
                             </div>
                             <div class="col-lg-10 col-lg-offset-2">
                                 <button class="btn btn-primary" type="submit">Submit</button>
                             </div>
                         </fieldset>
                     </xsl:when>
                     <xsl:otherwise>
                         <xsl:for-each select="option">
                         <div>
                             <div class="radio">
                                 <label>
                                     <input id="optionsRadios1" type="radio" value="option1" name="optionsRadios"/>
                                     <xsl:apply-templates select="text"/>
                                 </label>
                             </div>
                         </div>
                         <div>
                             <xsl:apply-templates select="action"/>
                         </div>
                     </xsl:for-each>
                     </xsl:otherwise>
                 </xsl:choose>
             </form>
         </div>
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
         <xsl:if test="h2">
             <h2> <xsl:value-of select="h2"/> </h2>
         </xsl:if>
         <xsl:if test="h3">
             <h3> <xsl:value-of select="h3"/> </h3>
         </xsl:if>
         <xsl:apply-templates select="check | img | list | p"/>
     </xsl:template>

     <xsl:template match="person">
         <person name="{@name}">
             <xsl:value-of select="text() | person"/>
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

