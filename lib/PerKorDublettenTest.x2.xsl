<xsl:stylesheet version="2.0"
	xmlns:mpx="http://www.mpx.org/mpx"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />
	
	<!-- 2013-12-19 DEBUGGING TRANSFORM TO IDENTIFY NON-UNIQUE PERKORs Walk through the
		new data. All of the perKor must still be there. -->
	<xsl:template match="/*">
		<xsl:copy>
			<xsl:for-each select="/mpx:museumPlusExport/mpx:personKörperschaft">
				<xsl:variable name="kueId" select="@kueId"/>
				<xsl:variable name="datum" select="@exportdatum"/>
				
				<xsl:choose>
					<xsl:when test="document('temp/legacyPerKor.mpx')/mpx:museumPlusExport/mpx:personKörperschaft
						[(@kueId=$kueId) and (@exportdatum = $datum) ]">
					</xsl:when>
					<xsl:otherwise>
						<xsl:message>
							<xsl:value-of select="@kueId, @exportdatum, ' NOT OK', document('temp/legacyPerKor.mpx')/mpx:museumPlusExport/mpx:personKörperschaft[@kueId=$kueId]/@exportdatum"/>
						</xsl:message>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:copy>
		
	</xsl:template>
</xsl:stylesheet>