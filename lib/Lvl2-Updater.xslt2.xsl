<xsl:stylesheet version="2.0"
	xmlns:mpx="http://www.mpx.org/mpx"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	
	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />
	
	<!-- 2013-12-19
	A new updater transform. It merges two mpx documents
	a) is specified via input
	b) is temp/legacyPerKor.mpx	
	if there are multiple records for individual mulId,objId,kueId it keeps only the 
	one with newest exportdatum.

	Use saxon.pl and don't forget to move your output file to temp/legacyPerKor.mpx
	if you want keep adding more mpx content. 

	This skript also sorts mulId,kueId, objId.
	-->
	
	<xsl:template match="/*">
		<xsl:copy>
			<xsl:for-each-group select="/mpx:museumPlusExport/mpx:multimediaobjekt|document ('temp/mpxjoiner.tmp')/mpx:museumPlusExport/mpx:multimediaobjekt"
				group-by="@mulId">
				<xsl:sort data-type="number" select="@mulId"/>
				<xsl:for-each select="current-group()">
					<xsl:sort order="descending" select="@exportdatum"/>
					<xsl:if test="position() = 1">
						<xsl:copy-of select="."/>
					</xsl:if>
				</xsl:for-each>
			</xsl:for-each-group>
			
			<!-- We need all the PK we can get to generate perKorRef@ids -->
			<xsl:for-each-group select="/mpx:museumPlusExport/mpx:personKörperschaft|document
				('temp/mpxjoiner.tmp')/mpx:museumPlusExport/mpx:personKörperschaft" group-by="@kueId">
				<xsl:sort data-type="number" select="@kueId"/>
				<xsl:for-each select="current-group()">
					<xsl:sort order="descending" select="@exportdatum"/>
					<xsl:if test="position() = 1">
						<xsl:copy-of select="."/>
						<xsl:message>
							<xsl:value-of select="@kueId, @exportdatum"/>
						</xsl:message>
					</xsl:if>
				</xsl:for-each>
			</xsl:for-each-group>
			
			
			<xsl:for-each-group select="/mpx:museumPlusExport/mpx:sammlungsobjekt| document ('temp/mpxjoiner.tmp')/mpx:museumPlusExport/mpx:sammlungsobjekt"
				group-by="@objId">
				<xsl:sort data-type="number" select="@objId"/>
				<xsl:for-each select="current-group()">
					<xsl:sort order="descending" select="@exportdatum"/>
					<xsl:if test="position() = 1">
						<xsl:copy-of select="."/>
					</xsl:if>
				</xsl:for-each>
			</xsl:for-each-group>
			
		</xsl:copy>
		
	</xsl:template>
</xsl:stylesheet>