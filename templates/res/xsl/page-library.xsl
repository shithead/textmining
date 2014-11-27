<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <xsl:import href="html/tei.xsl"/> 
    <xsl:template match="/">
    <html>
        <head>
            <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
            <meta charset="utf-8" />
            <link rel="stylesheet" href="css/bootstrap.min.css" media="screen" />
        </head>
        <body>
            <xsl:apply-imports/>
            <script src="js/jquery-1.js"></script>
            <script src="js/bootstrap.js"></script>
        </body>
    </html>
    </xsl:template>
</xsl:stylesheet>
