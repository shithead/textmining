<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
    xmlns:tei="http://www.tei-c.org/ns/1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    exclude-result-prefixes="tei">
    <xsl:output indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>

    <xsl:template match="action">
        <xsl:apply-templates select="ctext | url"/>
    </xsl:template>

    <xsl:template match="answer">
        <div class="well bs-component">
            <form class="form-horizontal">
                <xsl:choose>
                    <xsl:when test="@type='form'">
                        <fieldset>
                            <xsl:for-each select="option">
                                <xsl:call-template name="option-form-group"/>
                            </xsl:for-each>
                            <div class="col-lg-10 col-lg-offset-2">
                                <button class="btn btn-primary" type="submit">Submit</button>
                            </div>
                        </fieldset>
                    </xsl:when>
                    <xsl:otherwise>
                        <!-- <xsl:when test="@type='radio'"> -->
                        <!-- ugly hack -->
                        <div class="tab-content">
                            <xsl:for-each select="option">
                                <xsl:call-template name="option-radio"/>
                            </xsl:for-each>
                        </div>
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
         <xsl:variable name="id" select="@id"/>
         <xsl:variable name="bibo">
             <xsl:apply-templates select="text() | person"/>
         </xsl:variable>
         <xsl:variable name="library_content">
             <xsl:choose>
                 <xsl:when test="/page/libraries">
                     <xsl:for-each select="/page/libraries/library">
                             <!-- concatination hack -->
                             <xsl:variable name="path">
                                 <xsl:value-of select="text()"/>
                             </xsl:variable>
                             <xsl:if test="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]">
                                 <xsl:value-of select="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]"/>
                             </xsl:if>
                     </xsl:for-each>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:for-each select="/course/module/meta/libraries/library">
                             <!-- concatination hack -->
                             <xsl:variable name="path">
                                 <xsl:value-of select="text()"/>
                             </xsl:variable>
                             <xsl:if test="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]">
                                 <xsl:value-of select="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]"/>
                             </xsl:if>
                     </xsl:for-each>
                 </xsl:otherwise>
             </xsl:choose>
         </xsl:variable>
         <bib class="message" id="{$id}" page="{@page}">
             <span>

                 <a class="css-truncate css-truncate-target" title="{$library_content}">
                     <xsl:value-of select="$bibo"/>
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

     <xsl:template match="corpus">
         <div class="well bs-component">
             <form class="form-horizontal">
                 <fieldset>
                     <div class="form-group">
                         <label class="col-lg-2 control-label" for="select">
                             <xsl:text> Fenstergröße </xsl:text>
                         </label>
                         <div class="col-lg-2">
                             <select id="select" class="form-control">
                                 <xsl:apply-templates select="range">
                                     <xsl:with-param name="end" select="0"/>
                                     <xsl:with-param name="id" select="'one'"/>
                                 </xsl:apply-templates>
                                 <xsl:apply-templates select="range">
                                     <xsl:with-param name="it" select="1"/>
                                     <xsl:with-param name="id" select="'one'"/>
                                 </xsl:apply-templates>
                             </select>
                         </div>
                         <!-- seconde -->
                         <div class="col-lg-2">
                             <select id="select" class="form-control">
                                 <xsl:apply-templates select="range">
                                     <xsl:with-param name="end" select="0"/>
                                     <xsl:with-param name="id" select="'two'"/>
                                 </xsl:apply-templates>
                                 <xsl:apply-templates select="range">
                                     <xsl:with-param name="it" select="1"/>
                                     <xsl:with-param name="id" select="'two'"/>
                                 </xsl:apply-templates>
                             </select>
                         </div>
                     </div>
                     <div class="form-group">
                         <label class="col-lg-2 control-label" for="select">
                             <xsl:text> Wortsuche basierend auf </xsl:text>
                         </label>
                         <div class="col-lg-2">
                             <select id="select" class="form-control">
                                 <option value="wortforms" ><xsl:text>Wortform</xsl:text></option>
                                 <option value="lemma" ><xsl:text>Lemma</xsl:text></option>
                                 <option value="pos"   ><xsl:text>POS</xsl:text></option>
                             </select>
                         </div>
                     </div>
                     <xsl:if test="frequence[@node='enable']">
                         <div class="form-group">
                             <label class="col-lg-2 control-label" for="select">
                                 <xsl:text> mind. Frequenz des Suchwortes </xsl:text>
                             </label>
                             <div class="col-lg-2">
                                 <input type="text" id="inputminnode" class="form-control"/>
                             </div>
                         </div>
                     </xsl:if>
                     <xsl:if test="frequence[@collocate='enable']">
                         <div class="form-group">
                             <label class="col-lg-2 control-label" for="select">
                                 <xsl:text> mind. Frequenz des Kollokators </xsl:text>
                             </label>
                             <div class="col-lg-2">
                                 <input type="text" id="inputmincollocator" class="form-control"/>
                             </div>
                         </div>
                     </xsl:if>
                     <div class="form-group">
                         <label class="col-lg-2 control-label" for="select">
                             <xsl:text> Signifikanzmaß </xsl:text>
                         </label>
                         <div class="col-lg-2">
                             <select id="select" class="form-control">
                                 <xsl:if test="statistic/@chi">
                                     <option value="chi" ><xsl:text>Chi-Quadrat</xsl:text></option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@dice">
                                     <option value="dice">
                                         <xsl:text>Dice-Koeffizient (not supported) </xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@frequence">
                                     <option value="frequence" >
                                         <xsl:text>sortiert nach Frequenz</xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@llr">
                                     <option value="llr" >
                                         <xsl:text>Log-Likelihood-Ratio (LLR)</xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@mi">
                                     <option value="mi" >
                                         <xsl:text>Mutual information (not supported) </xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@mi3">
                                     <option value="mi3" >
                                         <xsl:text>MI3 (not supported) </xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@tscore">
                                     <option value="tscore" >
                                         <xsl:text>T-Score (not supported) </xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@zscore">
                                     <option value="zscore" >
                                         <xsl:text>Z-Score (not supported) </xsl:text>
                                     </option>
                                 </xsl:if>
                             </select>           
                         </div>
                     </div>
                     <div class="form-group">
                         <label class="col-lg-2 control-label" for="select">
                             <xsl:text> Ein Suchwort </xsl:text>
                         </label>
                         <div class="col-lg-2">
                             <input type="text" id="inputDefault" class="form-control"/>
                         </div>
                     </div>
                     <div class="col-lg-10 col-lg-offset-2">
                         <button class="btn btn-primary" type="submit">Submit</button>
                     </div>
                 </fieldset>
             </form>
         </div>
     </xsl:template>

     <xsl:template match="course">
         <xsl:apply-templates select="meta | module"/>
     </xsl:template>

     <xsl:template match="date">
         <time><xsl:value-of select="text()"/></time>
     </xsl:template>

     <!-- XXX  -->
     <xsl:template match="details">
         <xsl:variable name="it" select='generate-id(current())'/>
         <div class="tab-content">
             <div class="tab-pane active" id="{$it}2">
                 <div class="glyphicon glyphicon-plus" data-toggle="tab" data-target="#{$it}"><b> Detail</b></div>
             </div>
             <div class="tab-pane" id="{$it}">
                 <div class="glyphicon glyphicon-minus" data-toggle="tab" data-target="#{$it}2"><b> Detail</b></div>
                 <span>
                     <xsl:apply-templates select="list | p"/>
                 </span>
             </div>
         </div>
     </xsl:template>

     <xsl:template match="emph">
         <b>
             <xsl:value-of select="text()"/>
         </b>
     </xsl:template>

     <xsl:template match="exercise">
         <xsl:apply-templates select="ctext | corpus"/>
         <!-- <xsl:if test="ctest=current()">
         <xsl:call-template name="ctext"/>
     </xsl:if>
         <xsl:call-template name="answer"/> -->
     </xsl:template>

     <xsl:template match="foreign">
         <xsl:value-of select="text()"/>
     </xsl:template>

     <xsl:template match="h1">
         <div class="page-header">
             <h1>
                 <xsl:apply-templates select="text() | term"/>
             </h1>
         </div>
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
             <xsl:when test="@type='details'">
                 <li class="hidden">
                     <xsl:apply-templates select="text() | bib | emph | foreign | img | kursiv | person | term | url"/>
                 </li>
             </xsl:when>
             <xsl:otherwise>
                 <li>
                     <xsl:apply-templates select="text() | bib | emph | foreign | img | kursiv | person | term | url"/>
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
         <xsl:apply-templates select="ctext | action"/>
     </xsl:template>

     <xsl:template match="option" name="option-form-group">
         <div class="form-group">
             <label class="col-lg-2 control-label" for="select">
                 <xsl:apply-templates select="ctext"/>
             </label>
             <xsl:variable name="csize" select='round(10 div last())'/>
             <xsl:for-each select="action">
                 <div class="col-lg-{$csize}">
                     <xsl:choose>
                         <xsl:when test="normalize-space(.) != ''">
                             <select id="select" class="form-control">
                                 <xsl:for-each select="ctext">
                                     <option><xsl:apply-templates select="current()"/></option>
                                 </xsl:for-each>
                             </select>           
                         </xsl:when>
                         <xsl:otherwise>  <input type="text" id="inputDefault" class="form-control"/>
                         </xsl:otherwise>
                     </xsl:choose>
                 </div>
             </xsl:for-each>
         </div>
     </xsl:template>

     <xsl:template match="option" name="option-radio">
         <xsl:variable name="it" select='generate-id(current())'/>
         <div class="radio">
             <label>
                 <input id="optionsRadios{$it}" type="radio" value="option{$it}" name="optionsRadios"  data-toggle="tab" data-target="#{$it}"/>
                 <xsl:apply-templates select="ctext"/>
             </label>
         </div>
         <br />
         <div class="tab-pane" id="{$it}">
             <xsl:apply-templates select="action"/>
         </div>
     </xsl:template>

     <xsl:template match="p">
         <xsl:choose>
             <xsl:when test="@type='quote'">
                 <div class="row">
                     <div class="col-lg-6">
                         <div class="bs-component">
                             <blockquote>
                                 <p>
                                     <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                                 </p>
                                 <small>
                                     <cite title="bib[@id]">
                                         <xsl:apply-templates select="bib" />
                                     </cite>
                                 </small>
                             </blockquote>
                         </div>
                     </div>
                 </div>
             </xsl:when>
             <xsl:when test="@type='details'">
                 <xsl:variable name="it" select='generate-id(current())'/>
                 <div class="tab-content">
                     <div class="tab-pane active" id="{$it}2">
                         <div class="glyphicon glyphicon-plus" data-toggle="tab" data-target="#{$it}"><b> Detail</b></div>
                     </div>
                     <div class="tab-pane" id="{$it}">
                         <div class="glyphicon glyphicon-minus" data-toggle="tab" data-target="#{$it}2"><b> Detail</b></div>
                         <span>
                             <p>
                                 <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term"/>
                             </p>
                         </span>
                     </div>
                 </div>
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
         <xsl:choose>
             <xsl:when test="count(p)=1 and not(check or exercise or img or list)">
                 <div class="bs-component">
                     <div class="jumbotron">
                         <xsl:apply-templates select="h1 | h2 | h3 | p"/>
                     </div>
                 </div>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:apply-templates select="h1 | h2 | h3 | check | exercise | img | list | p"/>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>

     <xsl:template match="person">
         <person name="{@name}">
             <xsl:value-of select="text() | person"/>
         </person>
     </xsl:template>

     <xsl:template match="term">
         <dfn><xsl:apply-templates select="text() | emph | foreign | kursiv"/></dfn>
     </xsl:template>

     <xsl:template match="ctext">
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
         <xsl:apply-templates select="ctext"/>
     </xsl:template>

     <xsl:template match="range">
         <xsl:param name="it" select="@from"/>
         <xsl:param name="end" select="@to + 1"/>
         <xsl:param name="id"/>
         <xsl:copy-of select="."/>
         <xsl:if test="$it &lt; $end">
             <xsl:choose>
                 <xsl:when test="$it=@standard">
                     <option selected="" value="range{$id}={$it}" ><xsl:value-of select="$it"/></option>
                 </xsl:when>
                 <xsl:otherwise>
                     <option value="range{$id}={$it}" ><xsl:value-of select="$it"/></option>
                 </xsl:otherwise>
             </xsl:choose>
             <xsl:apply-templates select=".">
                 <xsl:with-param name="it" select="$it + 1"/>
                 <xsl:with-param name="end" select="$end"/>
                 <xsl:with-param name="id" select="$id"/>
             </xsl:apply-templates>
         </xsl:if>
     </xsl:template>

     <xsl:template match="url">
         <a href="{@href}"><xsl:value-of select="text()"/></a>
     </xsl:template>

     <xsl:template match="version">
         <xsl:value-of select="text()"/>
     </xsl:template>
 </xsl:stylesheet>

