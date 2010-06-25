<xsl:stylesheet version="2.0" xmlns="http://www.mpx.org/mpx"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:mpx="http://www.mpx.org/mpx" exclude-result-prefixes="mpx">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!--
		sort elements after fixing made a mess
	-->

	<xsl:template match="/">
		<museumPlusExport
			xsi:schemaLocation="http://www.mpx.org/mpx file:/c:/cygwin/home/Mengel/usr/levelup/lib/mpx-lvl2.v2.xsd">

			<xsl:for-each
				select="/mpx:museumPlusExport/mpx:multimediaobjekt">
				<xsl:sort data-type="number" select="@mulId" />
				<xsl:element name="{name()}">
					<xsl:for-each select="@*">
						<xsl:attribute name="{name()}">
							<xsl:value-of select="." />
						</xsl:attribute>
					</xsl:for-each>

					<!-- <xsl:value-of select="." /> -->

					<xsl:for-each select="descendant::*">
						<xsl:sort data-type="text" lang="de"
							select="name(.)" />
						<xsl:copy>
							<xsl:copy-of select="@*" />
							<xsl:value-of select="." />
						</xsl:copy>
					</xsl:for-each>
				</xsl:element>
			</xsl:for-each>

			<!-- personKörperschaft -->

			<xsl:for-each
				select="/mpx:museumPlusExport/mpx:personKörperschaft">
				<xsl:sort data-type="number" select="@kueId" />
				<xsl:element name="{name()}">
					<xsl:for-each select="@*">
						<xsl:attribute name="{name()}">
							<xsl:value-of select="." />
						</xsl:attribute>
					</xsl:for-each>

					<!-- <xsl:value-of select="." /> -->

					<xsl:for-each select="descendant::*">
						<xsl:sort data-type="text" lang="de"
							select="name(.)" />
						<xsl:copy>
							<xsl:copy-of select="@*" />
							<xsl:value-of select="." />
						</xsl:copy>
					</xsl:for-each>
				</xsl:element>
			</xsl:for-each>

			<!-- SAMMLUNGSOBJEKT -->

			<xsl:for-each
				select="/mpx:museumPlusExport/mpx:sammlungsobjekt">
				<xsl:sort data-type="number" select="@objId" />
				<xsl:element name="{name()}">
					<xsl:for-each select="@*">
						<xsl:attribute name="{name()}">
							<xsl:value-of select="." />
						</xsl:attribute>
					</xsl:for-each>

					<!-- <xsl:value-of select="." /> -->

					<xsl:for-each select="descendant::*">
						<xsl:sort data-type="text" lang="de"
							select="name(.)" />
						<xsl:copy>
							<xsl:copy-of select="@*" />
							<xsl:value-of select="." />
						</xsl:copy>
					</xsl:for-each>
				</xsl:element>
			</xsl:for-each>

		</museumPlusExport>
	</xsl:template>
</xsl:stylesheet>


<!-- xsl:message>DEBUUGUUG</xsl:message
	<xsl:attribute name="objId" select="./@objId" />
	<xsl:for-each select="descendant::*">
	<xsl:sort select="name()" />
	drop empty elements
	and count(./@*) ne 0
	<xsl:if test=". ne ''">
	<xsl:element name="{name()}">
	<xsl:for-each select="@*">
	<xsl:if test=". ne ''">
	<xsl:attribute name="{name()}">
	<xsl:value-of select="." />
	</xsl:attribute>
	</xsl:if>
	</xsl:for-each>
	<xsl:value-of select="." />
	</xsl:element>
	</xsl:if>
	</xsl:for-each>
-->