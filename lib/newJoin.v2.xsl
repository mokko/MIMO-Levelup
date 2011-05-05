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
			<xsl:for-each-group select="/museumPlusExport/item[@mulId]|document ('temp/B.xml')/museumPlusExport/item[@mulId]" group-by="@mulId">
				<xsl:sort data-type="number" select="current-grouping-key()"/>
				<xsl:variable select="current-grouping-key()" name="currentId"/>
				<xsl:message>
					<xsl:value-of select=" 'mulId',$currentId"/>
				</xsl:message>
				<xsl:copy-of select="." />
		</xsl:copy>

	</xsl:template>
</xsl:stylesheet>