<?xml version="1.0"?>
<xsl:stylesheet version="1.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:museumdat="http://museum.zib.de/museumdat">
	<xsl:output method="html" encoding="UTF-8" />

	<!-- 
		Maurice: Ich habe das Format ein wenig verändert. Es fängt jetzt mit in logischer Weise 
		mit H1 an und jetzt mit H2 fort anstelle von H3 und einem b. Als Resultat lässt sich 
		besonders im Ausdruck (auf Papier) besser lesen. 
		Außerdem Großschreibung modifiziert.13.11.2007
	-->

	<xsl:template match="/">
		<html>
			<title>
				<xsl:value-of select="//museumdat:repositoryName" />
			</title>
			<style type="text/css">body { font-family:'Arial' }</style>
			<body>
				<xsl:for-each select="//museumdat:museumdat">
					<xsl:call-template name="museumdat" />
				</xsl:for-each>
			</body>
		</html>
	</xsl:template>

	<xsl:template name="Main">
		<xsl:for-each select="*">
			<xsl:choose>
				<xsl:when test="contains(name(),'Wrap')">
					<xsl:call-template name="Wrap" />
				</xsl:when>
				<xsl:when test="contains(name(),'Set')">
					<xsl:call-template name="Set" />
				</xsl:when>
				<!-- Sonderbehandlung indexingDates, einziges Element ohne Datenwert, das nicht als Set bezeichnet ist -->
				<xsl:when test="contains(name(),'indexingDates')">
					<xsl:call-template name="Set" />
				</xsl:when>
				<xsl:otherwise>
					<xsl:call-template name="Data" />
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="museumdat">
		<hr></hr>
		<h1>
			<xsl:value-of select="museumdat:administrativeMetadata/museumdat:recordWrap/museumdat:recordType" />
			Nr.
			<xsl:value-of select="museumdat:administrativeMetadata/museumdat:recordWrap/museumdat:recordID" />
		</h1>
		<xsl:for-each select="museumdat:descriptiveMetadata/*">
			<xsl:if test="*">
				<h2 style="text-transform:capitalize">
					<xsl:value-of
						select="substring-before(substring-after(name(),'museumdat:'),'Wrap')" />
				</h2>
				<xsl:call-template name="Main" />
			</xsl:if>
		</xsl:for-each>

		<xsl:for-each select="museumdat:administrativeMetadata">
			<h2 style="text-transform:capitalize">
				<xsl:value-of
					select="substring-after(name(),'museumdat:')" />
			</h2>
			<xsl:call-template name="Main" />
		</xsl:for-each>
	</xsl:template>

	<xsl:template name="Wrap">
		<table>
			<tbody>
				<tr>
					<td>
						<xsl:call-template name="Main" />
					</td>
				</tr>
			</tbody>
		</table>
	</xsl:template>

	<xsl:template name="Set">
		<xsl:if test="*">
			<table width="100%" bgcolor="#e2e2e2">
				<tbody>
					<tr>
						<td colspan="2" align="left">
							<i>
								<xsl:value-of
									select="substring-after(name(),'museumdat:')" />
							</i>
							<xsl:for-each select="@*">
								(
								<xsl:value-of
									select="substring-after(name(),'museumdat:')" />
								:
								<xsl:value-of select='.' />
								)
							</xsl:for-each>
						</td>
					</tr>
					<tr>
						<td width="5" />
						<td>
							<xsl:call-template name="Main" />
						</td>
					</tr>
				</tbody>
			</table>
		</xsl:if>
	</xsl:template>

	<xsl:template name="Data">
		<xsl:variable name="Wert" select="." />
		<xsl:if test="$Wert!=''">
			<div style="background-color:#f2f2f2">
				<xsl:value-of
					select="substring-after(name(),'museumdat:')" />
				:
				<b>
					<xsl:value-of select="." />
				</b>
				<xsl:for-each select="@*">
					(
					<xsl:value-of
						select="substring-after(name(),'museumdat:')" />
					:
					<xsl:value-of select='.' />
					)
				</xsl:for-each>
				<br></br>
			</div>
			<xsl:call-template name="Main" />
		</xsl:if>
	</xsl:template>


</xsl:stylesheet>