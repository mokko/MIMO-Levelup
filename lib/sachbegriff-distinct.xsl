<?xml version="1.0" encoding="UTF-8"?>


<xsl:stylesheet version="2.0" xmlns="http://www.mpx.org/mpx"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mpx="http://www.mpx.org/mpx">

    <xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
    <xsl:strip-space elements="*"/>


    <xsl:template match="/">
        <mpx:test>
            <xsl:for-each-group select="//mpx:sachbegriff" group-by=".">
                <xsl:sort lang="de" select="."/>
               <xsl:variable name="currentname" select="name(.)"/>
                <xsl:element name="mpx:sachbegriff">                
                    <xsl:attribute name="count"><xsl:value-of select="count ( current-group() )"/></xsl:attribute>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:for-each-group>

            <xsl:for-each-group select="//mpx:titel" group-by=".">
                <xsl:sort lang="de" select="."/>
                <xsl:variable name="currentname" select="name(.)"/>
                <xsl:element name="mpx:titel">
                    <xsl:attribute name="count"><xsl:value-of select="count ( current-group() )"/></xsl:attribute>
                    <xsl:value-of select="."/>
                </xsl:element>
            </xsl:for-each-group>
        </mpx:test>
    </xsl:template>

</xsl:stylesheet>
