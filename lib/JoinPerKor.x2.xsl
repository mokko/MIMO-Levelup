<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:mpx="http://www.mpx.org/mpx">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!-- 
		2013-12-19
		The old join adds up everything that it is fed. The new join should be more
		selective and see that it takes only one (the newest) record per perkor@kueId.

		result of old join:
		multimediaobjekt@mulId=1
		multimediaobjekt@mulId=2
		sammlungsobjekt@id=1
			personKörperschaftRef@kueId=1
			verknüpftesObjekt=1
		sammlungsobjekt@id=2
			personKörperschaftRef@kueId=1
			verknüpftesObjekt=2
		personKörperschaft@kueId=1
		personKörperschaft@kueId=1   <-problem
				Take unique kueId from both docs, where kueId not unique pick the most recent export.
				
				-->

	<xsl:template match="/*">
		<xsl:copy>
			<xsl:for-each-group select="/mpx:museumPlusExport/mpx:personKörperschaft|document ('temp/legacyPerKor.mpx')/mpx:museumPlusExport/mpx:personKörperschaft" group-by="@kueId">
				<xsl:sort data-type="number" select="@kueId"/>
				<xsl:sort order="descending" select="@exportdatum"/>
				
				<xsl:message>
					<xsl:value-of select="@kueId, @exportdatum"/>
				</xsl:message>
				<xsl:copy-of select="current-group()[1]" />
			</xsl:for-each-group>
		</xsl:copy>

	</xsl:template>
</xsl:stylesheet>