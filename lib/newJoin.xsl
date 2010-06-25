<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:mpx="http://www.mpx.org/mpx">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!-- 
		This skript is supposed to join heterogenously structured xml documents. 
		I try to do it generically as long as possible. 
		As input I want to use all .xml documents in the present folder
	-->

	<!--  
		Problems: At present repeated information is repeated in the output document
		Question: At which level do I want to eliminate redundant information? 
		On the level of the join or on the level of the distinctify?
		When joining collections see: colJoin.xsl
	-->

	<xsl:template match="/*">
		<xsl:copy>
			<xsl:for-each select="/*/*|document ('temp/B.xml')/*/*">
				<xsl:sort select="name()" order="ascending"/>
				<!-- xsl:sort select="@mulId|@kueId|@objId" /-->
				<xsl:copy-of select="." />
			</xsl:for-each>
		</xsl:copy>

	</xsl:template>
</xsl:stylesheet>