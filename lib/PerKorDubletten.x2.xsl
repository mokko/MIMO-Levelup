<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:mpx="http://www.mpx.org/mpx">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!-- 
		2013-12-19 DEBUGGING TRANSFORM TO IDENTIFY NON-UNIQUE PERKORs
				-->

	<xsl:template match="/*">
		<xsl:copy>
			<!--document('a.xml')//id[.=document('b.xml')//id]-->
			<xsl:copy-of select="/mpx:museumPlusExport/mpx:personKörperschaft[@kueId=document ('temp/legacyPerKor.mpx')/mpx:museumPlusExport/mpx:personKörperschaft/@kueId]" />	
		</xsl:copy>

	</xsl:template>
</xsl:stylesheet>