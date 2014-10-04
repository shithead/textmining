<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:output indent="yes" encoding="UTF-8" omit-xml-declaration="yes"/>

    <xsl:template match="listBibl">
        <xsl:apply-templates select="biblStruct"/>
    </xsl:template>

    <xsl:template match="biblStruct">
        <xsl:apply-templates select="analytic | monogr | series | idno"/>
    </xsl:template>

    <xsl:template match="analytic">
        <xsl:apply-templates select="title | author"/>
    </xsl:template>

    <xsl:template match="monogr">
        <xsl:apply-templates select="title | author | editor | edition | imprint"/>
    </xsl:template>

    <xsl:template match="series">
        <xsl:apply-templates select="title"/>
    </xsl:template>

    <xsl:template match="idno">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="title">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="author">
        <xsl:apply-templates select="name | forename | surname"/>
    </xsl:template>

    <xsl:template match="editor">
        <xsl:apply-templates select="forename | surname"/>
    </xsl:template>

    <xsl:template match="edition">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="name">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="forename">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="surname">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="imprint">
        <xsl:apply-templates select="note | pubPlace | publisher | biblScope | date"/>
    </xsl:template>

    <xsl:template match="biblScope">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="pubPlace">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="publisher">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

    <xsl:template match="date">
        <xsl:apply-templates select="text()"/>
    </xsl:template>

 </xsl:stylesheet>
