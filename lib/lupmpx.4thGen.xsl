<xsl:stylesheet version="2.0" xmlns="http://www.mpx.org/mpx"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:mpx="http://www.mpx.org/mpx"
	exclude-result-prefixes="mpx">

	<!-- it seems to me that this sometimes work with and sometimes doesn't with mpx -->


	<!--
		24.04.2010 
		XSD Pfad geändert

		25.03.2008 
		- beim neuen XSD Pfad File:// ergänzt für mpx.xsd, weil der validator von oXygen das gerne so hätte
		- Reihenfolge für element ton korrigiert.
		- Wenn mulId="" kann lasse, diesen DS unter den Tisch fallen!
		
		09.03.2008 verarbeitete attribut exportdatum in /*/*/@exportdatum
		in lvl1 und setzte es in jedes item objekt. Immer nur das
		Neueste Datum.

		28.02.2008 schemaLocation changed to improve xsd validation

		13.11.2007
		4th generation: for the first time only one the levelup
		transformation for multimediaobjekte, personenKörperschaften,
		sammlungsobjekte

		erwerbNr hinzugefügt

		-alt-
		Newline Problem! z.B. bei Titel müsste in rtftable2xml geändert werden!
		Kompromiss mit Perl, dass Titel trennt.
	-->


	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:strip-space elements="*"/>

	<xsl:template match="/">
		<museumPlusExport
			xsi:schemaLocation="http://www.mpx.org/mpx file:/c:/cygwin/home/Mengel/usr/levelup/lib/mpx-lvl2.v2.xsd">

			<!-- jedes sibling mit gleicher objId -->


			<!--
				BTW:
				-	Each PerKör(dependent) can have only one function (attribute of a kind,
				if there should be more, seemlingly the last one would be taken by
				this script)!
			-->

			<xsl:for-each-group select="/museumPlusExport/item[@mulId]" group-by="@mulId">
				<xsl:sort data-type="number" select="current-grouping-key()"/>
				<xsl:variable select="current-grouping-key()" name="currentId"/>
				<xsl:message>
					<xsl:value-of select=" 'mulId',$currentId"/>
				</xsl:message>

				<xsl:if test="@mulId ne '' ">
					<xsl:element name="multimediaobjekt">
						<xsl:attribute name="mulId">
							<xsl:value-of select="$currentId"/>
						</xsl:attribute>

						<xsl:attribute name="exportdatum">
							<xsl:for-each-group select="/museumPlusExport/item[@mulId]/@exportdatum"
								group-by=".">
								<xsl:sort data-type="text" order="descending"/>
								<xsl:if test="position() = 1">
									<xsl:value-of select="."/>
								</xsl:if>
							</xsl:for-each-group>
						</xsl:attribute>

						<!--
						independents and dependents mixed to get alphabetical order
						dependents: where several fields belong together!
					-->

						<!-- independents -->
						<xsl:for-each-group select="/museumPlusExport/item[@mulId=$currentId]"
							group-by="multimediaBearbDatum">

							<xsl:if test="exists (multimediaBearbDatum)">
								<xsl:element name="bearbDatum">
									<xsl:value-of select="multimediaBearbDatum"/>
								</xsl:element>
							</xsl:if>
						</xsl:for-each-group>

						<xsl:for-each
							select="(
						multimediaAnfertDat,
						multimediaBemerkFoto,
						multimediaDateiname,
						multimediaErweiterung,
						multimediaFarbe,
						multimediaFormat,
						multimediaFotoNegNr,
						multimediaFunktion,
						multimediaInhaltAnsicht,
						multimediaMatTechn,
						multimediaPersonenKörperschaft,
						multimediaPfadangabe,
						multimediaTyp,
						multimediaUrhebFotograf)">
							<xsl:variable name="tag" select="."/>
							<!--
							<xsl:message select="$tag">message</xsl:message>
						-->

							<xsl:call-template name="independents">
								<xsl:with-param name="currentId" select="$currentId"/>
								<xsl:with-param name="tag" select="$tag"/>
							</xsl:call-template>
						</xsl:for-each>

						<xsl:for-each-group select="/museumPlusExport/item[@mulId=$currentId]"
							group-by="objId">

							<xsl:if test="exists (objId)">
								<xsl:element name="verknüpftesObjekt">
									<xsl:value-of select="objId"/>
								</xsl:element>
							</xsl:if>
						</xsl:for-each-group>
					</xsl:element>
				</xsl:if>
			</xsl:for-each-group>







			<!--
				v5 08/09/2007
				- changed to 3rdGen
				- it would be good to have an error tracing: I wd like to see all
				the tags that were not processed

				v4
				- <item> changed to <personKörperschaft>
				- <verknüpftesObjekt> verweist jetzt auf genau 1 verknüpftes
				Objekt durch objId; kann wiederholt werden

				PROBLEME
				-	Newline Problem! z.B. bei Titel müsste in rtftable2xml geändert werden!
				Kompromiss mit Perl, dass Titel trennt.

				BTW:
				-	Each PerKör(dependent) can have only one function (attribute of a kind,
				if there should be more, seemlingly the last one would be taken by
				this script)!
			-->
			<xsl:for-each-group select="/museumPlusExport/item[@kueId]" group-by="@kueId">
				<xsl:sort data-type="number" select="current-grouping-key()"/>
				<xsl:variable select="current-grouping-key()" name="currentId"/>
				<xsl:message>
					<xsl:value-of select="$currentId"/>
				</xsl:message>

				<xsl:element name="personKörperschaft">
					<xsl:attribute name="kueId">
						<xsl:value-of select="$currentId"/>
					</xsl:attribute>

					<xsl:attribute name="exportdatum">
						<xsl:for-each-group select="/museumPlusExport/item[@kueId]/@exportdatum"
							group-by=".">
							<xsl:sort data-type="text" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:value-of select="."/>
							</xsl:if>
						</xsl:for-each-group>
					</xsl:attribute>

					<!--
						independents and dependents mixed to get alphabetical order
						dependents: where several fields belong together!
					-->

					<!-- artKörpersch -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="artKörpersch">
						<xsl:element name="artKörpersch">
							<xsl:value-of select="artKörpersch"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- bearbDatum -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="bearbDatum">
						<xsl:element name="bearbDatum">
							<xsl:value-of select="bearbDatum"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- bemerkungen -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="bemerkungen">
						<xsl:element name="bemerkungen">
							<xsl:value-of select="bemerkungen"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- berufTätigkeit -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="berufTätigkeit">
						<xsl:element name="berufTätigkeit">
							<xsl:value-of select="berufTätigkeit"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- biographie -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="biographie">
						<xsl:element name="biographie">
							<xsl:value-of select="biographie"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- datierung -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="datierung">
						<datierung>
							<xsl:for-each select="datierungArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="datierung"/>
						</datierung>
					</xsl:for-each-group>

					<!-- geogrBezug - geoBezug -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="geoBezug">
						<geogrBezug>
							<xsl:for-each select="geoBezugBezeichnung">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bezeichnung">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:for-each select="geoBezugArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="geoBezug"/>
						</geogrBezug>
					</xsl:for-each-group>

					<!-- kurzbiographie -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="kurzbiographie">
						<xsl:element name="kurzbiographie">
							<xsl:value-of select="kurzbiographie"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- name -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="name">
						<name>
							<xsl:for-each select="nameArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="name"/>
						</name>
					</xsl:for-each-group>

					<!-- nationalität -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="nationalität">
						<xsl:element name="nationalität">
							<xsl:value-of select="nationalität"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- nennform -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="nennform">
						<nennform>
							<xsl:for-each select="nennformArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="nennform"/>
						</nennform>
					</xsl:for-each-group>

					<!-- quelle -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="quelle">
						<xsl:element name="quelle">
							<xsl:value-of select="quelle"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- titelStand -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="titelStand">
						<xsl:element name="titelStand">
							<xsl:value-of select="titelStand"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- typ -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="typ">
						<xsl:element name="typ">
							<xsl:value-of select="typ"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- verantwortlich -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="verantwortlich">
						<xsl:element name="verantwortlichkeit">
							<xsl:value-of select="verantwortlich"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- verknüpftesObjekt: that's the new way to do it -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="verknüpftesObjekt">
						<xsl:element name="verknüpftesObjekt">
							<xsl:value-of select="verknüpftesObjekt"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- Altes VerknüpftesObjekt: that's a pseudo-old way to do it (will be replaced) -->
					<xsl:for-each-group select="/museumPlusExport/item[@kueId=$currentId]"
						group-by="objektIdentNr">
						<xsl:element name="verknüpftesObjektAlt">
							<xsl:if test="objektSachbegriff ne ''">
								<xsl:attribute name="objektSachbegriff">
									<xsl:value-of select="objektSachbegriff"/>
								</xsl:attribute>
							</xsl:if>
							<xsl:value-of select="objektIdentNr"/>
						</xsl:element>
					</xsl:for-each-group>
				</xsl:element>
			</xsl:for-each-group>




			<!--
				v5 09/08/07
				-with xsd, sorting according to objId, alphabetical order corrected

				v4
				PROBLEME
				-	Newline Problem! z.B. bei Titel müsste in rtftable2xml geändert werden!
				Kompromiss mit Perl, dass Titel trennt.

				BTW:
				-	Each PerKör(dependent) can have only one function (attribute of a kind,
				if there should be more, seemlingly the last one would be taken by
				this script)!

				Er guckt für independents nur in den ersten DS! Er soll aber in alle gucken.
				SOLVED! But now it takes even longer!

			-->
			<xsl:for-each-group select="/museumPlusExport/item[@objId]" group-by="@objId">
				<xsl:sort data-type="number" select="current-grouping-key()"/>
				<xsl:variable select="current-grouping-key()" name="currentId"/>

				<!-- xsl:variable name="exportdatum"
					select="/museumPlusExport/item[@objId]/@exportdatum" / -->

				<xsl:message>
					<xsl:value-of select="$currentId"/>
				</xsl:message>
				<xsl:element name="sammlungsobjekt">
					<xsl:attribute name="objId">
						<xsl:value-of select="$currentId"/>
					</xsl:attribute>

					<xsl:attribute name="exportdatum">
						<xsl:for-each-group select="/museumPlusExport/item[@objId]/@exportdatum"
							group-by=".">
							<xsl:sort data-type="text" order="descending"/>
							<xsl:if test="position() = 1">
								<xsl:value-of select="."/>
							</xsl:if>
						</xsl:for-each-group>
					</xsl:attribute>

					<!--
						independents and dependents mixed to get alphabetical order
						dependents: where several fields belong together!
					-->

					<!-- abbildungen -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="abbildungen">
						<xsl:element name="abbildungen">
							<xsl:value-of select="abbildungen"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- allgAngabeBeschriftung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="allgAngabeBeschriftung">
						<xsl:element name="allgAngabeBeschriftung">
							<xsl:value-of select="allgAngabeBeschriftung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- aktuellerStandort -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="aktuellerStandort">
						<xsl:element name="aktuellerStandort">
							<xsl:value-of select="aktuellerStandort"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- andereNr -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="andereNr">
						<andereNr>
							<xsl:for-each select="andereNrArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="andereNrBemerkung">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bemerkung">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="andereNr"/>
						</andereNr>
					</xsl:for-each-group>

					<!-- anzahlTeile -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="anzahlTeile">
						<xsl:element name="anzahlTeile">
							<xsl:value-of select="anzahlTeile"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- bearbDatum -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="bearbDatum">
						<xsl:element name="bearbDatum">
							<xsl:value-of select="bearbDatum"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- belichtungszeit -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="belichtungszeit">
						<xsl:element name="belichtungszeit">
							<xsl:value-of select="belichtungszeit"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- bemerkung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="bemerkung">
						<xsl:element name="bemerkung">
							<xsl:value-of select="bemerkung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- bemerkungSammlung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="bemerkungSammlung">
						<xsl:element name="bemerkungSammlung">
							<xsl:value-of select="bemerkungSammlung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- besetzung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="besetzung">
						<xsl:element name="besetzung">
							<xsl:value-of select="besetzung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- besitzart -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="besitzart">
						<xsl:element name="besitzart">
							<xsl:value-of select="besitzart"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- blende -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="blende">
						<xsl:element name="blende">
							<xsl:value-of select="blende"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- credits -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="credits">
						<xsl:element name="credits">
							<xsl:value-of select="credits"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- datierung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="datierung">
						<datierung>
							<xsl:for-each select="datierungArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungBemerkung">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bemerkung">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungBisJahr|datierungJahrBis">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bisJahr">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungBisMonat|datierungMonatBis">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bisMonat">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungBisTag|datierungTagBis">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bisTag">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungVonJahr|datierungJahrVon">
								<xsl:if test=". ne ''">
									<xsl:attribute name="vonJahr">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungVonMonat|datierungMonatVon">
								<xsl:if test=". ne ''">
									<xsl:attribute name="vonMonat">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="datierungVonTag|datierungTagVon">
								<xsl:if test=". ne ''">
									<xsl:attribute name="vonTag">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:value-of select="datierung"/>
						</datierung>
					</xsl:for-each-group>

					<!-- digitalisiert -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="digitalisiert">
						<xsl:element name="digitalisiert">
							<xsl:value-of select="digitalisiert"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- dokumentation -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="dokumentation">
						<xsl:element name="dokumentation">
							<xsl:value-of select="dokumentation"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- erwerbDatum -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="erwerbDatum">
						<xsl:element name="erwerbDatum">
							<xsl:value-of select="erwerbDatum"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- erwerbNotiz -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="erwerbNotiz">
						<xsl:element name="erwerbNotiz">
							<xsl:value-of select="erwerbNotiz"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- erwerbNr -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="erwerbNr">
						<xsl:element name="erwerbNr">
							<xsl:value-of select="erwerbNr"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- erwerbungsart -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="erwerbungsart">
						<xsl:element name="erwerbungsart">
							<xsl:value-of select="erwerbungsart"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- erwerbungVon -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="erwerbungVon">
						<xsl:element name="erwerbungVon">
							<xsl:value-of select="erwerbungVon"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- farbe -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="farbe">
						<xsl:element name="farbe">
							<xsl:value-of select="farbe"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- filmtyp -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="filmtyp">
						<xsl:element name="filmtyp">
							<xsl:value-of select="filmtyp"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- filter -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="filter">
						<xsl:element name="filter">
							<xsl:value-of select="filter"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- form -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="form">
						<xsl:element name="form">
							<xsl:value-of select="form"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- format -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="format">
						<xsl:element name="format">
							<xsl:value-of select="format"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- geogrBezug -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="geogrBezug">
						<geogrBezug>
							<xsl:for-each select="geogrBezugBezeichnung">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bezeichnung">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:for-each select="geogrBezugArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:for-each select="geogrBezugKommentar">
								<xsl:if test=". ne ''">
									<xsl:attribute name="kommentar">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="geogrBezug"/>
						</geogrBezug>
					</xsl:for-each-group>

					<!-- handling -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="handling">
						<xsl:element name="handling">
							<xsl:value-of select="handling"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- identNr-->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="identNr">
						<identNr>
							<xsl:for-each select="identNrArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="identNr"/>
						</identNr>
					</xsl:for-each-group>

					<!-- ikonographischeBeschreibung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="ikonographischeBeschreibung">
						<xsl:element name="ikonographischeBeschreibung">
							<xsl:value-of select="ikonographischeBeschreibung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- ikonographischeKurzbeschreibung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="ikonographischeKurzbeschreibung">
						<xsl:element name="ikonographischeKurzbeschreibung">
							<xsl:value-of select="ikonographischeKurzbeschreibung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- inhalt -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="inhalt">
						<xsl:element name="inhalt">
							<xsl:value-of select="inhalt"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- instrumente -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="instrumente">
						<xsl:element name="instrumente">
							<xsl:value-of select="instrumente"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- inventarNotiz -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="inventarNotiz">
						<xsl:element name="inventarNotiz">
							<xsl:value-of select="inventarNotiz"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- kamera -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="kamera">
						<xsl:element name="kamera">
							<xsl:value-of select="kamera"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- kameratyp -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="kameratyp">
						<xsl:element name="kameratyp">
							<xsl:value-of select="kameratyp"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- kategorieGenre -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="kategorieGenre">
						<xsl:element name="kategorieGenre">
							<xsl:value-of select="kategorieGenre"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- konvolut -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="konvolut">
						<xsl:element name="konvolut">
							<xsl:value-of select="konvolut"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- kurzeBeschreibung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="kurzeBeschreibung">
						<xsl:element name="kurzeBeschreibung">
							<xsl:value-of select="kurzeBeschreibung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- langeBeschreibung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="langeBeschreibung">
						<xsl:element name="langeBeschreibung">
							<xsl:value-of select="langeBeschreibung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- leihgeber -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="leihgeber">
						<xsl:element name="leihgeber">
							<xsl:value-of select="leihgeber"/>
						</xsl:element>
					</xsl:for-each-group>


					<!-- maßangaben-->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="maßangaben">
						<maßangabe>
							<xsl:for-each select="maßangabenTyp">
								<xsl:if test=". ne ''">
									<xsl:attribute name="typ">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="maßangaben"/>
						</maßangabe>
					</xsl:for-each-group>

					<!-- materialTechnik-->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="materialTechnik">
						<materialTechnik>
							<xsl:for-each select="materialTechnikArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:for-each select="materialTechnikBesonderheit">
								<xsl:if test=". ne ''">
									<xsl:attribute name="besonderheit">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="materialTechnik"/>
						</materialTechnik>
					</xsl:for-each-group>

					<!-- musikgattung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="musikgattung">
						<xsl:element name="musikgattung">
							<xsl:value-of select="musikgattung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- nadelschliff -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="nadelschliff">
						<xsl:element name="nadelschliff">
							<xsl:value-of select="nadelschliff"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- objektiv -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="objektiv">
						<xsl:element name="objektiv">
							<xsl:value-of select="objektiv"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- objekttyp -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="objekttyp">
						<xsl:element name="objekttyp">
							<xsl:value-of select="objekttyp"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- objStatus -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="objStatus">
						<xsl:element name="objStatus">
							<xsl:value-of select="objStatus"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- Objekt-Objekt-Beziehungen (OOV) -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="objBezIdentNr">
						<xsl:element name="oov">
							<xsl:for-each select="objBezArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="objBezBemerkung">
								<xsl:if test=". ne ''">
									<xsl:attribute name="bemerkung">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>

							<xsl:for-each select="objBezSachbegriff">
								<xsl:if test=". ne ''">
									<xsl:attribute name="sachbegriff">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>


							<xsl:value-of select="objBezIdentNr"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- personenKörperschaften -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="personenKörperschaften">
						<personKörperschaftRef>
							<xsl:for-each select="personenArtDesBezugs">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:for-each select="personenKörperschaftenFunktion">
								<xsl:if test=". ne ''">
									<xsl:attribute name="funktion">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="personenKörperschaften"/>
						</personKörperschaftRef>
					</xsl:for-each-group>

					<!-- sachbegriff-->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="sachbegriff">
						<sachbegriff>
							<xsl:for-each select="sachbegriffArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="sachbegriff"/>
						</sachbegriff>
					</xsl:for-each-group>

					<!-- schnitt -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="schnitt">
						<xsl:element name="schnitt">
							<xsl:value-of select="schnitt"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- stativ -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="stativ">
						<xsl:element name="stativ">
							<xsl:value-of select="stativ"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- stelleFilm-->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="stelleFilm">
						<xsl:element name="stelleFilm">
							<xsl:value-of select="stelleFilm"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- ständigerStandort -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="ständigerStandort">
						<xsl:element name="ständigerStandort">
							<xsl:value-of select="ständigerStandort"/>
						</xsl:element>
					</xsl:for-each-group>


					<!--
						SWD
						TODO: check if it works, because of different order in m+template!
					-->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="swd">
						<swd>
							<xsl:for-each select="swdArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="swd"/>
						</swd>
					</xsl:for-each-group>

					<!-- systematikArt -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="systematikArt">
						<xsl:element name="systematikArt">
							<xsl:value-of select="systematikArt"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- technischeBemerkung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="technischeBemerkung">
						<xsl:element name="technischeBemerkung">
							<xsl:value-of select="technischeBemerkung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- textOriginal -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="textOriginal">
						<xsl:element name="textOriginal">
							<xsl:value-of select="textOriginal"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- titel -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="titel">
						<titel>
							<xsl:for-each select="titelArt">
								<xsl:if test=". ne ''">
									<xsl:attribute name="art">
										<xsl:value-of select="."/>
									</xsl:attribute>
								</xsl:if>
							</xsl:for-each>
							<xsl:value-of select="titel"/>
						</titel>
					</xsl:for-each-group>

					<!-- ton -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="ton">
						<xsl:element name="ton">
							<xsl:value-of select="ton"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- tvNorm -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="tvNorm">
						<xsl:element name="tvNorm">
							<xsl:value-of select="tvNorm"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- veranstaltung -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="veranstaltung">
						<xsl:element name="veranstaltung">
							<xsl:value-of select="veranstaltung"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- verantwortlichkeit -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="verantwortlichkeit">
						<xsl:element name="verantwortlichkeit">
							<xsl:value-of select="verantwortlichkeit"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- verfügbareFormate -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="verfügbareFormate">
						<xsl:element name="verfügbareFormate">
							<xsl:value-of select="verfügbareFormate"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- verwaltendeInstitution -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="verwaltendeInstitution">
						<xsl:element name="verwaltendeInstitution">
							<xsl:value-of select="verwaltendeInstitution"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- verwendetesLicht -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="verwendetesLicht">
						<xsl:element name="verwendetesLicht">
							<xsl:value-of select="verwendetesLicht"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- vorlage -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="vorlage">
						<xsl:element name="vorlage">
							<xsl:value-of select="vorlage"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- zielgruppe -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="zielgruppe">
						<xsl:element name="zielgruppe">
							<xsl:value-of select="zielgruppe"/>
						</xsl:element>
					</xsl:for-each-group>

					<!-- zusatzgeräte -->
					<xsl:for-each-group select="/museumPlusExport/item[@objId=$currentId]"
						group-by="zusatzgeräte">
						<xsl:element name="zusatzgeräte">
							<xsl:value-of select="zusatzgeräte"/>
						</xsl:element>
					</xsl:for-each-group>

				</xsl:element>
			</xsl:for-each-group>


		</museumPlusExport>
	</xsl:template>

	<xsl:template name="independents">
		<xsl:param name="currentId"/>
		<xsl:param name="tag"/>

		<!--
			<xsl:message select="$tag"/>
			<xsl:message select="$currentId"/>
		-->
		<xsl:for-each-group select="/museumPlusExport/item[@mulId=$currentId]" group-by="name($tag)">

			<xsl:if test="exists ($tag)">
				<xsl:element name="{name($tag)}">
					<xsl:value-of select="$tag"/>
				</xsl:element>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:template>
</xsl:stylesheet>
