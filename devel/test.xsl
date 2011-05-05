<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns="http://www.mpx.org/mpx"
	xmlns:mpxvok="http://www.mpx.org/mpxvok"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />

	<xsl:strip-space elements="*" />

	<xsl:template match="/">
		<xsl:variable name="dictloc" select="document('lib/mpxvok.xml')"/>
		<xsl:variable name="dictloc" select="document('file:///c:/cygwin/home/Mengel/usr/levelup/lib/mpxvok.xml')"/>
		<xsl:value-of select="$dictloc/mpxvok:mpxvok" />
	</xsl:template>
</xsl:stylesheet>

