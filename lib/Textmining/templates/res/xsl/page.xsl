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
                         <xsl:choose>
                             <xsl:when test="document($path)">
                                 <xsl:choose>
                                     <xsl:when test="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]">
                                         <xsl:value-of select="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]"/>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:message>library: in <xsl:value-of select="$path"/> id <xsl:value-of select="$id"/> not found</xsl:message>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:when>
                             <xsl:otherwise>
                                 <xsl:message>library: <xsl:value-of select="$path"/> not found</xsl:message>
                             </xsl:otherwise>
                         </xsl:choose>
                     </xsl:for-each>
                 </xsl:when>
                 <xsl:otherwise>
                     <xsl:message>library: /page/libraries not found</xsl:message>
                     <xsl:choose>
                         <xsl:when test="/course/module/meta/libraries/library">
                             <xsl:for-each select="/course/module/meta/libraries/library">
                                 <xsl:variable name="path">
                                     <xsl:value-of select="text()"/>
                                 </xsl:variable>
                                 <xsl:choose>
                                     <xsl:when test="document($path)">
                                         <xsl:choose>
                                             <xsl:when test="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]">
                                                 <xsl:value-of select="document($path)/tei:listBibl/tei:biblStruct[@xml:id=$id]"/>
                                             </xsl:when>
                                             <xsl:otherwise>
                                                 <xsl:message>library: in <xsl:value-of select="$path"/> id <xsl:value-of select="$id"/> not found</xsl:message>
                                             </xsl:otherwise>
                                         </xsl:choose>
                                     </xsl:when>
                                     <xsl:otherwise>
                                         <xsl:message>library: <xsl:value-of select="$path"/> not found</xsl:message>
                                     </xsl:otherwise>
                                 </xsl:choose>
                             </xsl:for-each>
                         </xsl:when>
                         <xsl:otherwise>
                             <xsl:message>library: /course/module/meta/libraries/library not found</xsl:message>
                         </xsl:otherwise>
                     </xsl:choose>
                 </xsl:otherwise>
             </xsl:choose>
         </xsl:variable>
         <span class="message" id="{$id}" page="{@page}">
             <a class="css-truncate css-truncate-target" title="{$library_content}">
                 <xsl:value-of select="$bibo"/>
             </a>
         </span>
     </xsl:template>

     <xsl:template match="chapter">
         <div id="chapter_wrapper_{@id}" class="chapter-wrap" type="{@type}">
             <xsl:apply-templates select="page"/>
         </div>
     </xsl:template>

     <xsl:template match="check">
         <xsl:apply-templates select="question | answer"/>
     </xsl:template>

     <xsl:template match="collocation">
         <xsl:call-template name="corpus">
            <xsl:with-param name="corpus" select="@href"/>
         </xsl:call-template>
     </xsl:template>

     <xsl:template match="corpus" name='corpus' >
         <xsl:param name="corpus" select="@href"/>
         <xsl:variable name="form_id" select='generate-id(current())'/>
         <div class="row">
             <div class="col-sm-4">
                 <div class="bs-component">
                     <div id="modal_{$form_id}" class="modal">
                         <div class="modal-dialog">
                             <div class="modal-content">
                                 <div class="modal-header">
                                     <a class="close" aria-hidden="true" data-dismiss="modal" type="button">×</a>
                                     <h4 class="modal-title">
                                         <xsl:value-of select="$corpus"/>
                                     </h4>
                                 </div>
                                 <div id="modal_body_{$form_id}" class="modal-body">
                                     <p> foo bar </p>
                                 </div>
                                 <div class="modal-footer">
                                     <a class="btn btn-default" data-dismiss="modal" type="button">Close</a>
                                     <button class="btn btn-primary" type="button">Save</button>
                                 </div>
                             </div>
                         </div>
                     </div>
                 </div>
             </div>
         </div>
         <div class="well bs-component">
             <!--    <div class="alert alert-dismissable alert-warning">
                 <h4>Warning!</h4>
                 <p>corpus <xsl:value-of select="$corpus" /> not available</p>
             </div> -->
             <form id="{$form_id}" class="form-horizontal">
                 <fieldset>
                     <div class="form-group">
                         <label class="col-lg-3 control-label" for="select">
                             <xsl:text> Windowsize </xsl:text>
                         </label>
                         <div class="col-lg-3">
                             <select id="select_ws" class="form-control">
                                 <xsl:apply-templates select="range">
                                     <xsl:with-param name="it" select="2"/>
                                 </xsl:apply-templates>
                             </select>
                         </div>
                     </div>
                     <div class="form-group">
                         <label class="col-lg-3 control-label" for="select">
                             <xsl:text> Word searching based on </xsl:text>
                         </label>
                         <div class="col-lg-3">
                             <select id="select_search_for" class="form-control">
                                 <option value="wordforms" ><xsl:text>Word forms</xsl:text></option>
                                 <option value="lemma" ><xsl:text>Lemma</xsl:text></option>
                                 <option value="pos"   ><xsl:text>POS</xsl:text></option>
                             </select>
                         </div>
                     </div>
                     <xsl:if test="frequence[@node='enable']">
                         <div class="form-group">
                             <label class="col-lg-3 control-label" for="select">
                                 <xsl:text> min. frequency of searching word </xsl:text>
                             </label>
                             <div class="col-lg-3">
                                 <input type="text" id="input_min_node" class="form-control"/>
                             </div>
                         </div>
                     </xsl:if>
                     <xsl:if test="frequence[@collocate='enable']">
                         <div class="form-group">
                             <label class="col-lg-3 control-label" for="select">
                                 <xsl:text> min. frequency of collocate </xsl:text>
                             </label>
                             <div class="col-lg-3">
                                 <input type="text" id="input_min_collocator" class="form-control"/>
                             </div>
                         </div>
                     </xsl:if>
                     <div class="form-group">
                         <label class="col-lg-3 control-label" for="select">
                             <xsl:text> Signifikanzmaß </xsl:text>
                         </label>
                         <div class="col-lg-3">
                             <select id="select_statistic" class="form-control">
                                 <xsl:if test="statistic/@chi">
                                     <option value="x2" ><xsl:text>Chi-Square</xsl:text></option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@dice">
                                     <option value="dice">
                                         <xsl:text>Dice-Koeffizient (not supported) </xsl:text>
                                         <xsl:message>
                                             Dice-Koeffizient not supported 
                                         </xsl:message>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@frequence">
                                     <option value="frequence" >
                                         <xsl:text>sort on frequency</xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@llr">
                                     <option value="ll" >
                                         <xsl:text>Log-Likelihood-Ratio (LLR)</xsl:text>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@mi">
                                     <option value="mi" >
                                         <xsl:text>Mutual information (not supported) </xsl:text>
                                         <xsl:message>
                                            Mutual information not supported
                                         </xsl:message>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@mi3">
                                     <option value="mi3" >
                                         <xsl:text>MI3 (not supported) </xsl:text>
                                         <xsl:message>
                                             MI3 not supported
                                         </xsl:message>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@tscore">
                                     <option value="tscore" >
                                         <xsl:text>T-Score (not supported) </xsl:text>
                                         <xsl:message>
                                             T-Score not supported
                                         </xsl:message>
                                     </option>
                                 </xsl:if>
                                 <xsl:if test="statistic/@zscore">
                                     <option value="zscore" >
                                         <xsl:text>Z-Score (not supported) </xsl:text>
                                         <xsl:message>
                                             Z-Score not supported
                                         </xsl:message>
                                     </option>
                                 </xsl:if>
                             </select>
                         </div>
                     </div>
                     <div class="form-group">
                         <label class="col-lg-3 control-label" for="select">
                             <xsl:text> search word (only one) </xsl:text>
                         </label>
                         <div class="col-lg-3">
                             <input type="text" id="input_search" class="form-control"/>
                         </div>
                     </div>
                     <div class="col-lg-10 col-lg-offset-2">
                         <div class="col-sm-2">
                             <button class="btn btn-primary" formaction="javascript:get_corpus_data('{$form_id}','{$corpus}');" type="submit">Submit</button>
                         </div>
                         <div class="col-sm-2">
                             <a id="result_{$form_id}" class="btn btn-primary disabled" data-toggle="modal" href="javascript:modal_toggle('modal_{$form_id}');" type="button" disabled='' >Show Result</a>
                         </div>
                         <div class="col-sm-2">
                             <button class="btn btn-primary" type="reset">Reset</button>
                         </div>
                     </div>
                 </fieldset>
             </form>
         </div>
     </xsl:template>

     <xsl:template match="course">
         <xsl:apply-templates select="meta | module"/>
     </xsl:template>

     <xsl:template match="ctext">
         <xsl:apply-templates select="text() | details | list | p | term"/>
     </xsl:template>

     <xsl:template match="date">
         <time><xsl:value-of select="text()"/></time>
     </xsl:template>

     <xsl:template match="details">
         <xsl:variable name="it" select='generate-id(current())'/>
         <div class="tab-content">
             <div class="tab-pane active" id="{$it}2">
                 <div class="glyphicon glyphicon-plus" data-toggle="tab" data-target="#{$it}"><b> Detail</b></div>
             </div>
             <div class="tab-pane" id="{$it}">
                 <div class="glyphicon glyphicon-minus" data-toggle="tab" data-target="#{$it}2"><b> Detail</b></div>
                 <br />
                 <mark>
                     <xsl:apply-templates select="list | p"/>
                 </mark>
             </div>
         </div>
     </xsl:template>

     <xsl:template match="emph">
         <b>
             <xsl:apply-templates select="text() | kursiv"/>
         </b>
     </xsl:template>

     <xsl:template match="exercise">
         <xsl:apply-templates select="ctext | collocation | keywords"/>
         <!-- <xsl:if test="ctest=current()">
         <xsl:call-template name="ctext"/>
     </xsl:if>
         <xsl:call-template name="answer"/> -->
     </xsl:template>

     <xsl:template match="foreign">
         <i>
         <xsl:value-of select="text()"/>
         </i>
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
         <xsl:variable name="alttext"  select="text()"/>
         <xsl:choose>
             <xsl:when test="@type='svg'">
                 <object class="col-lg-12" type="image/svg+xml" data="{@src}" border="1"></object>
             </xsl:when>
             <xsl:otherwise>
                <img src="{@src}" alt="{$alttext}" class="img-responsive" />
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>

     <xsl:template match="keywords">
         <xsl:call-template name="corpus">
            <xsl:with-param name="corpus" select="@href"/>
         </xsl:call-template>
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
                                     <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | sub | sup | term"/>
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
             <!-- deprecated -->
             <xsl:when test="@type='details'">
                 <xsl:message>p with type details is deprecated</xsl:message>
                 <xsl:variable name="it" select='generate-id(current())'/>
                 <div class="tab-content">
                     <div class="tab-pane active" id="{$it}2">
                         <div class="glyphicon glyphicon-plus" data-toggle="tab" data-target="#{$it}"><b> Detail</b></div>
                     </div>
                     <div class="tab-pane" id="{$it}">
                         <div class="glyphicon glyphicon-minus" data-toggle="tab" data-target="#{$it}2"><b> Detail</b></div>
                         <span>
                             <p>
                                 <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | term | url"/>
                             </p>
                         </span>
                     </div>
                 </div>
             </xsl:when>
             <xsl:when test="@type='example'">
                 <p class="example">
                     <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | sub | sup | term | url"/>
                 </p>
             </xsl:when>
             <xsl:when test="@align='left'">
                 <p class="text-left">
                     <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | sub | sup | term | url"/>
                 </p>
             </xsl:when>
             <xsl:when test="@align='right'">
                 <p class="text-right">
                     <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | sub | sup | term | url"/>
                 </p>
             </xsl:when>
             <xsl:otherwise>
                 <p>
                     <xsl:apply-templates select="text() | a | bib | emph | foreign | img | kursiv | person | quantity | sub | sup | term | url"/>
                 </p>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>

     <xsl:template match="page">
         <xsl:choose>
             <xsl:when test="count(p)=1 and not(check or details or exercise or img or list)">
                 <div class="bs-component">
                     <div class="jumbotron">
                         <xsl:apply-templates select="h1 | h2 | h3 | p"/>
                     </div>
                 </div>
             </xsl:when>
             <xsl:otherwise>
                 <xsl:apply-templates select="h1 | h2 | h3 | check | details | exercise | img | list | p"/>
             </xsl:otherwise>
         </xsl:choose>
     </xsl:template>

     <xsl:template match="person">
         <person name="{@name}">
             <xsl:value-of select="text() | person"/>
         </person>
     </xsl:template>

     <xsl:template match="sub">
         <sub>
             <xsl:value-of select="text()"/>
         </sub>
     </xsl:template>

     <xsl:template match="sup">
         <sup>
             <xsl:value-of select="text()"/>
         </sup>
     </xsl:template>

     <xsl:template match="term">
         <dfn><xsl:apply-templates select="text() | emph | foreign | kursiv"/></dfn>
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
         <i>
            <xsl:value-of select="text()"/>
         </i>
     </xsl:template>

     <xsl:template match="question">
         <xsl:apply-templates select="ctext"/>
     </xsl:template>

     <xsl:template match="range">
         <xsl:param name="it" select="@from"/>
         <xsl:param name="end" select="@to + 1"/>
         <xsl:copy-of select="."/>
         <xsl:if test="$it &lt; $end">
             <xsl:choose>
                 <xsl:when test="$it=@standard">
                     <option selected="" value="{$it}" ><xsl:value-of select="$it"/></option>
                 </xsl:when>
                 <xsl:otherwise>
                     <option value="{$it}" ><xsl:value-of select="$it"/></option>
                 </xsl:otherwise>
             </xsl:choose>
             <xsl:apply-templates select=".">
                 <xsl:with-param name="it" select="$it + 1"/>
                 <xsl:with-param name="end" select="$end"/>
             </xsl:apply-templates>
         </xsl:if>
     </xsl:template>

     <!-- nicht dtd konform -->
     <xsl:template match="url">
         <a href="{@href}"><xsl:value-of select="text()"/></a>
     </xsl:template>

     <xsl:template match="version">
         <xsl:value-of select="text()"/>
     </xsl:template>
 </xsl:stylesheet>

