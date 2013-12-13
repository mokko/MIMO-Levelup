<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
	xmlns:museumdat="http://museum.zib.de/museumdat"
	xmlns:mpx="http://www.mpx.org/mpx" exclude-result-prefixes="mpx">

	<xsl:output method="xml" version="1.0" encoding="UTF-8"
		indent="yes" />
	<xsl:strip-space elements="*" />

	<!--
		v10 7.7.08
		Wenn Lange Beschreibung den Text "Bis zur Erweiterung des Textfeldes "Lange Beschreibung"" enthält, schneide ich den Rest weg
		TODO: Wenn ich richtig sehe, haben die Events bislang keine geogrBezug

		v9
		*schemaLocation ist jetzt ein zentraler path
		v8
		*WLehmann Fachreferat "Amerikanische Ethnologie" auch in repositoryLocationName


		v7 Diese Transformation ist urspruenglich entstanden, um Walter Lehmann-Daten möglichst gut
		in Museum zu übertragen. Nun geht es darum, eine standardisierte Art und Weise
		zu finden, um von M+ nach museumdat zu konvertieren. Ich arbeite zur Zeit an WLehmann und
		unseren CDs.
		Fragen an mich:
		-Die Verantwortlichkeit als mdat classification sagt eigentlich kaum etwas aus.
		-Gibt es ein accessedVia bei collection level?

		Vorschlaege fuer BAM und/oder Fachgruppe
		-M+Objekttyp ist fuer aussenstehende kaum interessant. Wie waere es, wenn man museumdat optional
		DCMIType verwendet. Ist allerdings nur fuer Medien sinnvoll.
		-Die Indexing Date-Werte sollten wahlweise XS:String oder XS:DateTime oder irgendein anderes
		kontrolliertes Date-Format sein.
		-Braucht man ein IsAccessedVia? z.B. als Eigenschaft von repositorySet
		-Braucht museumdat:descriptiveNoteSet ein pref Attribut in Analogie zu Titel?
		Oder soll ich vielleicht alle descriptiveNotes in ein Feld schreiben?
		-Ich finde museumdat, sollte etwas zur Behandlung von whitespace sagen und zwar, dass alles erlaubt ist,
		was XML auch erlaubt, dass sind eingeschraenkte Absaetze und andere Kontrollzeichen.
		-warum sind manche Attribute in Englisch, aber andere in Deutsch. Ich wuerde durchgaengig alles in Englisch haben und wahlweise, deutsch erlauben.
		-Es gibt irgendeine Konfusion mit <museumdat:indexingDates> und <museumdat:indexingDateSet> zwischen pdf-Specifikation und xsd

		TODO
		-Filter:event Ankauf Medienarchiv herausfiltern
		-sieh zu, dass jeder titleWrap genau einen preferred titel
		-neue Type Attribute fuer descriptiveNote

		v6 11/15/07 nach Besprechung mit Fr. Fischer und B. Gliesmann
		* TODO: ResourceLink für Foto-Export verändert. Auch Dateiendung erledigt!
		* wir schlagen vor, die Klassifikation "Allgemein" wegzulassen, weil diese Info
		ziemlich nichtssagend ist. D.h. immer wenn "Allgemein", dann nichts. DONE.MM.
		* Zeichenkette "EM-Am Archäologie" ersetzt mit "Fachreferat Amerikanische Archäologie" ersetzen. DONE. MM.
		Es tauchte die Frage auf, ob das nicht in das Feld repositoryName gehört. -> RS fragen?
		* Frage, ob SPK und SMB in repositoryName gehören und wenn ja in welcher Reihenfolge -> RS?
		* displayCreationLocation: Leerzeichen weglassen, Reihenfolge der Einträge unklar. Keine Lösung.
		* ".(HK)" in descriptiveNote  heißt, dass der Eintrag so aus dem Hauptkatalog zitiert wurde.
		In Museumdat weglassen. Erledigt.
		* Feldlängenbegrenzung in lange Beschreibung. Müsste beim nächsten Export weg sein
		(M+ Problem, das inzwischen erledigt sein sollte.) Zu überprüfen!
		* Erledigt: Sammelereignis. Hat Sammler, keine Zeit, keine Ort.
		* Erledigt: Ankauf hat Veräußerer|Vorbesitzer|Mäzen, Erwerbdatum, keinen Ort!
		* TODO: Forschungsreise (immer wenn "Reise" in Erwerbnotiz) hat feste Zeit 1907-1909,
		W.Lehmann
		* TODO: Grabungsergebnis. Person? keine Zeit, kein Ort
		* TODO: Herkunftsereignis. hat Zeit und Ort (erledigt), aber noch offen: ggf. SystematikArt-Eintrag
		* Erledigt: nur noch Bilder, die Kürzel "BAM" im Feld FotoNg.Nr.
		* Erledigt: Zeichenkette "Objektmaß" mit "Höhe x Breite x Tiefe" ersetzen.


		v5 11/13/07
		ERLEDIGT
		*indexingMeasurements exportieren, für BAM nicht notwendig.
		*encodinganalog und label eingeführt (MM). Ich beziehe mich nicht direkt auf M+,
		sondern auf das MuseumPlusXML (MPX). Letzteres bezieht sich auf MuseumPlus und
		verwendet dessen Screennamen. In MPX sind es jedoch interne Namen, also: encodinganalog
		und nicht label. Sollte mir mehr bei Debuggen helfen, als wenn ich hier M+ hinschreibe.
		*Zusammenhänge wie "Konvolut Velasco" in Inventarnotiz fallen unter den Tisch! Das nehmen wir in Kauf!
		*mehr Datumsfelder exportieren für Ereignisse.
		*ErwerbNr wird jetzt auch exportiert. Wurde aber in den am 22.10.07 exportierten Daten noch nicht exportiert. Wird aber in dieser Transformation schon berücksichtigt.
		*ErwerbNotiz und ErwerbArt lässt sich nicht zu museumdat mappen (Beschränkung von Exchange Format). Erledigt.
		*<museumdat:vitalDatesActor>
		TODO
		*Todo: oov - Zusamenhänge zu den Akten hätten wir gerne mit deren objId unter
		<relatedWork> V.2.1.1 ID, V.2.1.2 Art der Verwandtschaft (verwandt mit") und V.2.1.? Link und Label!
		Link fehlt noch. Das machen wir frühestens zusammen mit den Bildern, wenn überhaupt.
		Hmm. Die objId ist nicht so einfach. Ich kann mit M+ die objIds nicht ausgeben, muss als Workaround dafür
		also alle Akten ausgeben, mit xpath in den Signaturen (ident.nr) nachschlagen, die eindeutig sein sollten
		und versuchen so die ObjId herauszufinden. Um mir diesen Aufwand vorläufig zu ersparen, nutze ich solange
		die bislang schon exportierten Signaturen (ident.nr).
		*TODO: Multimedia Dateiendung: Feld wird jetzt exportiert, ist aber bei dem Export vom 22.10. noch nicht dabei! Muss noch in dieser Transformation eingeführt werden.
		*TODO: Umformatieren des encoding schemes für erwerbDatum (falls wirklich notwendig)

		FRAGEN/UNKLAR
		*Ereignisse müssen noch überarbeitet werden
		*Welche Funktion haben funktionslose PerKörs? -> Boris/Fischer fragen TODO
		*hat das Sammerlergnis eine Datierung?
		*Eventtype hat offene Liste: Herstellung, Erwerbung, Schenkung, Herkunft... (kann meine Schrift nicht mehr lesen)
		*	was ist wenn geogr. und Namensangabe nicht qualifiziert sind, was bedeutet das?
		*Feld erwerbungVon wird exportiert allerdings ist im gesamten W.Lehmann-Konvolut nur ein DS
		in diesem Feld ausgefüllt. objId 107564 hat dort den nicht ganz durchsichtigen Eintrag "(Kauf)".
		*NEUER EREIGNISTYP "Herstellung":  geoBezug, Herkunft datierung prüfen
		*Display Elemente: sollen besser in einem zweiten  Schritt aus den Indexing Events erzeugt werden, nicht für Herstellung
		und nicht für Herkunft. Muss das wirklich sein oder können wir es für WLehmann so lassen?
		*TODO: Display Event nur sinnvoll, wenn Creator unbekannt, dann soll gar nichts ... ???


		v4 September 2007 Änderungen/Fragen (alle RS)
		* ?? SystematikArt / Objekttypen = label statt termsource
		* Anpassung schemaLocation
		* mpx-lvl2.v2.xsd: Korrektur ikonographischeBeschreibung (Leerzeichen weg)
		* Korrektur repositorySet für v1.0
		* ständiger Standort = repositoryLocationName
		* verantwortlich = classification statt repositoryName
		* indexingMeasurements auskommentiert
		* title: Falls kein Titel vorhanden, Sachbegriff ausgeben.
		Oder welches Feld entspricht Objektbezeichnung?
		* Was ist  oov art="Vorgang"
		* Konvolut Velasco - Zugehörigkeit erfasst?
		* <personKörperschaftRef>Velasco, José Maria</personKörperschaftRef>
		Welche Rolle hat der Herr -> welches Ereignis?

		v.2 10/09/07
		This version has been expects input from a joined lvl2 input containing all sets.

	-->


	<xsl:template match="/">
		<museumdat:museumdatWrap
			xsi:schemaLocation="http://museum.zib.de/museumdat File://C:/Perl/site/lib/xsd/museumdat-v1.0.xsd"
			museumdat:relatedencoding="MuseumPlusXML-lvl3">

			<xsl:apply-templates select="//mpx:sammlungsobjekt" />
		</museumdat:museumdatWrap>
	</xsl:template>


	<xsl:template match="mpx:sammlungsobjekt">
		<xsl:variable name="currentId" select="@objId" />
		<xsl:message select="string($currentId)" />
		<museumdat:museumdat>
			<museumdat:descriptiveMetadata>
				<!--
					I. Element: Objektklassifikation (Umschlag)
				-->
				<museumdat:objectClassificationWrap>
					<museumdat:objectWorkTypeWrap>
						<xsl:choose>
							<xsl:when
								test="exists(child::mpx:sachbegriff)">

								<xsl:for-each
									select="child::mpx:sachbegriff">
									<museumdat:objectWorkType
										museumdat:encodinganalog="mpx:sachbegriff"
										museumdat:termsource="EM-Objektsystematik">
										<xsl:value-of select="." />
									</museumdat:objectWorkType>
								</xsl:for-each>
							</xsl:when>
							<xsl:otherwise>
								<museumdat:objectWorkType>
									kein Sachbegriff vergeben
								</museumdat:objectWorkType>
							</xsl:otherwise>
						</xsl:choose>
					</museumdat:objectWorkTypeWrap>

					<museumdat:classificationWrap>
						<xsl:for-each
							select="child::mpx:systematikArt">
							<museumdat:classification
								museumdat:encodinganalog="mpx:systematikArt"
								museumdat:label="SystematikArt">
								<xsl:value-of select="." />
							</museumdat:classification>
						</xsl:for-each>

						<xsl:for-each select="child::mpx:objekttyp">
							<xsl:if test=". ne 'Allgemein'">
								<museumdat:classification
									museumdat:encodinganalog="mpx:objekttyp"
									museumdat:termsource="M+Objekttyp">
									<xsl:value-of select="." />
								</museumdat:classification>
							</xsl:if>

							<xsl:if test=". eq 'Audio' ">
								<!-- and mpx:sachbegriff ne 'CD-ROM'  -->
								<museumdat:classification
									museumdat:encodinganalog="mpx:objekttyp"
									museumdat:termsource="DCMIType"
									museumdat:termsourceID="sound">
									Sound
								</museumdat:classification>
							</xsl:if>
						</xsl:for-each>

						<xsl:if test=". eq 'Audio' ">
							<museumdat:classification
								museumdat:encodinganalog="mpx:objekttyp"
								museumdat:termsource="dmEntityType">
								Medium
							</museumdat:classification>
						</xsl:if>

						<xsl:for-each select="child::mpx:swd">
							<museumdat:classification
								museumdat:encodinganalog="mpx:swd" museumdat:termsource="SWD">
								<xsl:value-of select="." />
							</museumdat:classification>
						</xsl:for-each>

						<xsl:for-each
							select="child::mpx:verantwortlichkeit">
							<museumdat:classification
								museumdat:encodinganalog="mpx:verantwortlichkeit">
								<xsl:choose>
									<xsl:when
										test=". eq 'EM-Am Archäologie'">
										<xsl:value-of select="'Fachreferat Amerikanische Archäologie'" />
									</xsl:when>
									<xsl:otherwise>
										<xsl:value-of select="." />
									</xsl:otherwise>
								</xsl:choose>
							</museumdat:classification>
						</xsl:for-each>
					</museumdat:classificationWrap>
				</museumdat:objectClassificationWrap>


				<!--
					II. Element: Identifikation (Umschlag)
				-->
				<museumdat:identificationWrap>
					<museumdat:titleWrap>
						<xsl:choose>
							<xsl:when test="exists(child::mpx:titel)">
								<xsl:for-each
									select="child::mpx:titel">
									<museumdat:titleSet>
										<museumdat:title>
											<xsl:if
												test="position()=1">
												<xsl:attribute
													name="museumdat:pref">
													<xsl:value-of
														select="'preferred'" />
												</xsl:attribute>
											</xsl:if>
											<xsl:attribute
												name="museumdat:encodinganalog">
												<xsl:value-of
													select="'mpx:titel'" />
											</xsl:attribute>
											<xsl:value-of select="." />
										</museumdat:title>
									</museumdat:titleSet>
								</xsl:for-each>
							</xsl:when>
							<xsl:when
								test="exists(child::mpx:sachbegriff)">
								<museumdat:titleSet>
									<museumdat:title
										museumdat:type="Sachbegriff"
										museumdat:encodinganalog="mpx:sachbegriff"
										museumdat:pref="preferred">
										<xsl:value-of
											select="child::mpx:sachbegriff" />
									</museumdat:title>
								</museumdat:titleSet>
							</xsl:when>
							<xsl:otherwise>
								<museumdat:titleSet>
									<museumdat:title
										museumdat:pref="preferred">
										kein Titel
									</museumdat:title>
								</museumdat:titleSet>
							</xsl:otherwise>
						</xsl:choose>
					</museumdat:titleWrap>

					<!-- TODO mdat.inscription = M+Beschriftung AND M+Wiederholgruppe -->

					<museumdat:repositoryWrap>
						<museumdat:repositorySet
							museumdat:type="current">

							<!-- Can there be more than one verwaltendeInstitution? -->
							<xsl:for-each
								select="child::mpx:verwaltendeInstitution">
								<museumdat:repositoryName
									museumdat:encodinganalog="mpx:verwaltendeInstitution">
									<xsl:value-of select="." />
								</museumdat:repositoryName>
							</xsl:for-each>

							<xsl:for-each select="child::mpx:identNr">
								<museumdat:workID
									museumdat:encodinganalog="mpx:identNr"
									museumdat:type="Inventarnummer">
									<xsl:value-of select="." />
								</museumdat:workID>
							</xsl:for-each>

							<xsl:for-each
								select="child::mpx:andereNr">
								<museumdat:workID
									museumdat:encodinganalog="mpx:andereNr"
									museumdat:type="AndereNr">
									<xsl:value-of select="." />
								</museumdat:workID>
							</xsl:for-each>

							<!-- included in MPX but not yet exported with data at 22.10.07 -->
							<xsl:for-each
								select="child::mpx:erwerbNr">
								<museumdat:workID
									museumdat:encodinganalog="mpx:erwerbNr"
									museumdat:type="Zugangsnummer">
									<xsl:value-of select="." />
								</museumdat:workID>
							</xsl:for-each>

							<xsl:if
								test="exists (child::mpx:verantwortlichkeit or mpx:ständigerStandort)">
								<museumdat:repositoryLocationName
									museumdat:encodinganalog="child::mpx:verantwortlichkeit and mpx:ständigerStandort">
									<!-- NEW and difficult to test since I have no Standort with CDs usually -->
									<xsl:for-each
										select="child::mpx:verantwortlichkeit">
										<xsl:choose>
											<xsl:when
												test=". eq 'EM-Am Archäologie'">
												Fachreferat
												Amerikanische
												Archäologie
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of
													select="." />
											</xsl:otherwise>
										</xsl:choose>
										<xsl:if
											test="not(position()=last())">
											;
										</xsl:if>
										<xsl:if
											test="(position()=last()) and child::mpx:ständigerStandort">
											:
										</xsl:if>
									</xsl:for-each>
									<xsl:for-each
										select="child::mpx:ständigerStandort">
										<xsl:value-of select="." />
										<xsl:if
											test="not(position()=last())">
											;
										</xsl:if>
									</xsl:for-each>
								</museumdat:repositoryLocationName>
							</xsl:if>
						</museumdat:repositorySet>
					</museumdat:repositoryWrap>
				</museumdat:identificationWrap>


				<!--
					III. Element: Beschreibungen (Umschlag)
				-->
				<museumdat:descriptionWrap>
					<xsl:choose>
						<xsl:when
							test="exists(child::mpx:personKörperschaftRef[@funktion='Hersteller'])">
							<museumdat:displayCreator
								museumdat:encodinganalog="mpx:personKörperschaftRef">
								<xsl:for-each
									select="child::mpx:personKörperschaftRef[@funktion='Hersteller']">
									<xsl:value-of select="." />
									<xsl:if test="@funktion">
										<xsl:value-of
											select="string-join((' (',@funktion,')'),'')" />
									</xsl:if>
									<xsl:if
										test="not(position()=last())">
										;
									</xsl:if>
								</xsl:for-each>
							</museumdat:displayCreator>
						</xsl:when>

						<xsl:when
							test="exists(child::mpx:geogrBezug[@bezeichnung='Ethnie|Kultur'])">
							<museumdat:displayCreator
								museumdat:encodinganalog="mpx:personKörperschaftRef">
								<xsl:for-each
									select="child::mpx:geogrBezug[@bezeichnung='Ethnie|Kultur']">
									<xsl:value-of select="." />
									<xsl:if test="@bezeichnung">
										<xsl:value-of
											select="'(',@bezeichnung,')'" />
									</xsl:if>
									<xsl:if
										test="not(position()=last())">
										;
									</xsl:if>
								</xsl:for-each>
							</museumdat:displayCreator>
						</xsl:when>

					</xsl:choose>

					<museumdat:displayCreationDate
						museumdat:encodinganalog="mpx:datierung">
						<xsl:for-each
							select="child::mpx:datierung[art='Aufnahme' or 'Produktion' or 'Herstellung']">
							<xsl:value-of select="." />
							<xsl:if test="exists (@art)">
								<xsl:value-of
									select="string-join((' (',normalize-space(@art),')'),'')" />
							</xsl:if>
							<xsl:if test="not(position()=last())">
								<xsl:value-of select="'; '" />
							</xsl:if>
						</xsl:for-each>
					</museumdat:displayCreationDate>

					<museumdat:displayCreationLocation
						museumdat:encodinganalog="mpx:geogrBezug">

						<xsl:for-each select="child::mpx:geogrBezug">
							<xsl:if
								test="not(@bezeichnung = 'Ethnie|Kultur')">
								<xsl:if test="not(position() = 1)">
									<xsl:value-of select="'; '" />
								</xsl:if>
								<xsl:value-of select="." />

								<xsl:if test="exists(@bezeichnung)">
									<xsl:value-of
										select="string-join((' (',@bezeichnung),'')" />
									<xsl:if test="exists(@kommentar)">
										<xsl:value-of
											select="',',@kommentar" />
									</xsl:if>
									<xsl:value-of select="')'" />
								</xsl:if>
							</xsl:if>
						</xsl:for-each>
					</museumdat:displayCreationLocation>

					<xsl:choose>
						<!--  allgemeiner Fall -->
						<xsl:when
							test="child::mpx:verantwortlichkeit != 'EM-Medienarchiv' and
							exists(child::mpx:maßangabe)">
							<museumdat:displayMeasurements
								museumdat:encodinganalog="mpx:maßangabe">
								<xsl:for-each
									select="child::mpx:maßangabe">
									<xsl:if
										test="not(position() = 1)">
										<xsl:text>;</xsl:text>
									</xsl:if>
									<xsl:value-of select="." />
									<xsl:if test="exists(@typ)">
										<xsl:value-of
											select="string-join((' (',replace(@typ,'Objektmaß','Höhe x Breite x Tiefe'),')'),'')" />
									</xsl:if>
								</xsl:for-each>
							</museumdat:displayMeasurements>
						</xsl:when>
						<xsl:when
							test="child::mpx:verantwortlichkeit = 'EM-Medienarchiv'
							and child::mpx:sachbegriff eq 'CD' or 'Schellackplatte' or 'Kassette'
							or 'VCD' or 'DVD' or 'Schallplatte' or 'DAT' or 'Tonband' or 'Video'">
							<museumdat:displayMeasurements
								museumdat:encodinganalog="mpx:sachbegriff">
								<xsl:value-of
									select="child::mpx:sachbegriff,' (Format)'" />
							</museumdat:displayMeasurements>
						</xsl:when>
					</xsl:choose>


					<xsl:if
						test="child::mpx:materialTechnik[@art='Ausgabe']">
						<museumdat:displayMaterialsTech
							museumdat:encodinganalog="mpx:materialTechnik">
							<xsl:for-each
								select="child::mpx:materialTechnik[@art='Ausgabe']">
								<xsl:value-of select="." />
							</xsl:for-each>
						</museumdat:displayMaterialsTech>
					</xsl:if>

					<museumdat:descriptiveNoteWrap>
						<xsl:if
							test="exists(child::mpx:kurzeBeschreibung)">
							<museumdat:descriptiveNoteSet
								museumdat:type="short" museumdat:label="Kurze Beschreibung">
								<xsl:for-each
									select="child::mpx:kurzeBeschreibung">
									<museumdat:descriptiveNote
										museumdat:encodinganalog="mpx:kurzeBeschreibung">
										<!-- This is a fix and should be actually in the other xslt! -->
										<xsl:value-of
											select="replace(replace(.,'\(HK\)',''),'\. $|\.$','')" />
									</museumdat:descriptiveNote>
								</xsl:for-each>
							</museumdat:descriptiveNoteSet>
						</xsl:if>

						<xsl:if
							test="exists(child::mpx:langeBeschreibung)">
							<xsl:variable name="beschreibung" select="normalize-space(substring-before (.,'Bis zur Erweiterung des Textfeldes'))"/>
							<xsl:if test="$beschreibung != '' ">
								<museumdat:descriptiveNoteSet museumdat:type="long">
									<xsl:for-each select="child::mpx:langeBeschreibung">
										<museumdat:descriptiveNote
											museumdat:label="Lange Beschreibung"
											museumdat:encodinganalog="mpx:langeBeschreibung">
											<xsl:value-of select="$beschreibung"/>
										</museumdat:descriptiveNote>
									</xsl:for-each>
								</museumdat:descriptiveNoteSet>
							</xsl:if>
						</xsl:if>

						<xsl:if
							test="exists(child::mpx:ikonographischeBeschreibung)">
							<museumdat:descriptiveNoteSet
								museumdat:type="iconography">
								<xsl:for-each
									select="child::mpx:ikonographischeBeschreibung">
									<museumdat:descriptiveNote
										museumdat:label="ikonographische Beschreibung"
										museumdat:encodinganalog="mpx:ikonographischeBeschreibung">
										<xsl:value-of select="." />
									</museumdat:descriptiveNote>
								</xsl:for-each>
							</museumdat:descriptiveNoteSet>
						</xsl:if>

						<!-- exists only for records with objekttyp="audio" -->
						<xsl:if test="exists(child::mpx:inhalt)">
							<museumdat:descriptiveNoteSet
								museumdat:type="content">
								<xsl:for-each
									select="child::mpx:inhalt">
									<museumdat:descriptiveNote
										museumdat:encodinganalog="mpx:inhalt"
										museumdat:label="Inhalt (Audio)">
										Inhalt (Audio):
										<xsl:value-of select="." />
									</museumdat:descriptiveNote>
								</xsl:for-each>
							</museumdat:descriptiveNoteSet>
						</xsl:if>

						<!-- exists only for records with objekttyp="audio" -->
						<xsl:if test="exists(child::mpx:besetzung)">
							<museumdat:descriptiveNoteSet
								museumdat:type="content">
								<xsl:for-each
									select="child::mpx:besetzung">
									<museumdat:descriptiveNote
										museumdat:label="Besetzung (Audio)"
										museumdat:encodinganalog="mpx:besetzung">
										Besetzung (Audio):
										<xsl:value-of select="." />
									</museumdat:descriptiveNote>
								</xsl:for-each>
							</museumdat:descriptiveNoteSet>
						</xsl:if>
					</museumdat:descriptiveNoteWrap>
				</museumdat:descriptionWrap>



				<!--
					IV. Element: Ereignisse (Umschlag)

					Stell es dir so vor, dass die verschiedenen eventTypen nebeneinander stehen
					und nicht die unterschiedlichen Exportfiles. So hoffe ich mehr Code wiederverwenden zu koennen.
					Ausserdem sollen EventTypen in alphabetischer Reihenfolge stehen. Benutze keine Choose, die ueber mehr als
					einen Eventtyp gehen, um die Lesbarkeit zu verbessern. Am Anfang jedes EventTypen genaue Bedingungen, fuer
					welche Daten er gilt. Als Regel gilt, dass alle EM-Verantwortlichkeiten ihre eigenen Events bekommen.
					<Herstellung>
					<WLehmann>
					<1-EventType/>
					<2-Actors/>
					<3-Dates/>
					<4-Locations/>
					</WLehmann>
					</Herstellung>
					<Sammelereigniss>
					<WLehmann>
					<1-EventType/>
					<2-Actors/>
					<3-Dates/>
					<4-Locations/>
					</WLehmann>
					<Medienarchiv/>
					</Sammelereigniss>

					ULTIMATIVE LISTE DER BISHER DEFINIERTEN EVENTTYPEN IN DIESEM EXPORT:
					*Erwerbung
					*Herkunft (nicht in Spezifikation von museumdat 1.0, wird bestimmt irgendwann Herstellung)
					*Publikation
					*Sammelereignis

					Fuer jedes Ereignis:
					1-EventType
					2-Actors
					3-Dates
					4-Locations
				-->


				<museumdat:eventWrap>
					<museumdat:indexingEventWrap>
						<!-- DIE ERWERBUNG
							<erwerbDatum>1909</erwerbDatum>
							<erwerbNotiz>Reise</erwerbNotiz>
							<erwerbungsart>Ankauf</erwerbungsart>
							<erwerbungVon>

							Wo sollen erwerbNotiz und erwerbungsart untergebracht werden?

							erwerbungsart = eventType - Set wird aber nur angelegt, wenn zumindest ein
							Akteur oder ein erwerbDatum bekannt sind. Ort dazu? Keine Ort bei WLehmann!
							erwerbNotiz ist descriptiveNote, falls sie tatsächlich übernommen werden soll.
							In dem speziellen Fall erwerbNotiz="Reise" ist's spannend:
							CRM-mäßig eigentlich ein relatedEvent - ein Element, das
							wir perspektivisch sowieso als sub-element von indexingEventSet
							aufnehmen sollten.
							Boris wollte auch Reise als Event.
							<xsl:if
							test="exists(mpx:erwerbDatum|mpx:erwerbungVon|mpx:personKörperschaftRef[@funktion = 'Veräußerer']|mpx:personKörperschaftRef[@funktion = 'Mäzen']|mpx:personKörperschaftRef[@funktion = 'Vorbesitzer'])">
						-->
						<xsl:if
							test="not (mpx:verantwortlichkeit eq 'EM-Medienarchiv')">
							<xsl:if
								test="matches (mpx:erwerbungsart, 'Ankauf') or matches (mpx:erwerbungsart, 'Schenkung')">
								<museumdat:indexingEventSet>
									<!-- 1. EVENTTYPE -->
									<museumdat:eventType>
										<xsl:choose>
											<xsl:when
												test="exists(mpx:erwerbungsart)">
												<xsl:value-of
													select="mpx:erwerbungsart" />
											</xsl:when>
											<xsl:otherwise>
												Erwerbung
											</xsl:otherwise>
										</xsl:choose>
									</museumdat:eventType>
									<!-- 2. ACTORS -->
									<xsl:if
										test="exists(child::mpx:erwerbungVon)">
										<museumdat:indexingActorSet>
											<museumdat:nameActorSet>
												<museumdat:nameActor
													museumdat:encodinganalog="mpx:erwerbungVon">
													<xsl:value-of
														select="child::mpx:erwerbungVon" />
												</museumdat:nameActor>
											</museumdat:nameActorSet>
											<!-- Bislang in M+ des EM kaum erfasst, außerdem lässt sich Feld nicht exportieren
												<museumdat:nationalityActor>TODO</museumdat:nationalityActor>
											-->
											<museumdat:roleActor>
												Veräußerer
											</museumdat:roleActor>
										</museumdat:indexingActorSet>
									</xsl:if>

									<xsl:for-each
										select="mpx:personKörperschaftRef[@funktion = 'Veräußerer']|mpx:personKörperschaftRef[@funktion = 'Mäzen']|mpx:personKörperschaftRef[@funktion = 'Vermittler']|mpx:personKörperschaftRef[@funktion = 'Vorbesitzer']">
										<!--
											sollte moeglich sein, hier das Template indexingActorSet aufzurufen.
											Will das aber nicht ohne entsprechenden Test implementieren
										-->
										<museumdat:indexingActorSet>
											<museumdat:nameActorSet>
												<museumdat:nameActor
													museumdat:encodinganalog="mpx:personKörperschaftRef[@funktion]">
													<xsl:choose>
														<xsl:when
															test="mpx:personKörperschaft/typ = 'Person' or 'Künstler'">
															<xsl:attribute
																name="museumdat:type">
																<xsl:value-of
																	select="'personalName'" />
															</xsl:attribute>
														</xsl:when>
														<xsl:when
															test="mpx:personKörperschaft/typ = 'Körperschaft' or 'Sozietät' or 'Vertrieb'">
															<xsl:attribute
																name="museumdat:type">
																<xsl:value-of
																	select="'corporateName'" />
															</xsl:attribute>
														</xsl:when>
														<!-- sonst schreib lieber gar nichts hin! -->
													</xsl:choose>
													<xsl:value-of
														select="." />
												</museumdat:nameActor>
											</museumdat:nameActorSet>
											<museumdat:roleActor
												museumdat:encodinganalog="mpx:@funktion">
												<xsl:choose>
													<xsl:when
														test="@funktion">
														<xsl:value-of
															select="@funktion" />
													</xsl:when>
													<xsl:otherwise>
														Veräußerer
													</xsl:otherwise>
												</xsl:choose>
											</museumdat:roleActor>
										</museumdat:indexingActorSet>
									</xsl:for-each>
									<!-- 3. DATES -->
									<xsl:if
										test="exists(child::mpx:erwerbDatum)">
										<museumdat:indexingDates>
											<museumdat:earliestDate
												museumdat:encodinganalog="mpx:erwerbDatum">
												<xsl:value-of
													select="child::mpx:erwerbDatum" />
												<!--TODO: check and reformat Date format to YYYY-MM-DD-->
											</museumdat:earliestDate>
											<museumdat:latestDate
												museumdat:encodinganalog="mpx:erwerbDatum">
												<xsl:value-of
													select="child::mpx:erwerbDatum" />
											</museumdat:latestDate>
										</museumdat:indexingDates>
									</xsl:if>
									<!-- 4. NO LOCATIONS -->
								</museumdat:indexingEventSet>
							</xsl:if>
						</xsl:if>


						<!-- Die HERSTELLUNG / HERKUNFT
							erledigt: Herkunftsort aus GeogrBez wenn kein Qualifikator oder wenn explizit Herstellung
							Bemerkung: Leider wurde bei der Eingabe in M+ versäumt, die Funktion des Ortes anzugeben.
							Wir haben uns entschieden, die Ortsangabe ohne weitere Klassifikation
							allgemein als Herkunft zu betrachten.
							RS: WICHTIG: Herkunft? Gebrauch? Fund? Herstellung?? GeogrBez enthält keinen
							Qualifikator! Ggf. sind datierung und geogrBez in zwei Ereignisse aufzuteilen
							Sind hier wirklich ALLE Ortsangaben zu übernehmen?? Bis auf weiteres ja (MM).
							Was ist hiermit anzufangen?? art?? kommentar?? Datenwert=Fundort??
							<sammlungsobjekt objId="102820">
							<geogrBezug>Nicaragua</geogrBezug>
							<geogrBezug bezeichnung="Insel">Zapatera</geogrBezug>
							<geogrBezug art="Guabillo"
							kommentar="Der Fundort ist mit dem Gräberfeld Pta. de la Figuras identisch.">
							(Fundort)</geogrBezug>

						-->
						<!-- Herkunftsereignis fuer WLehmann -->
						<xsl:if
							test="mpx:verantwortlichkeit eq 'EM-Am Archäologie'">
							<xsl:if
								test="exists(child::mpx:datierung/@vonJahr ) or exists(child::mpx:datierung/@vonJahr)">
								<museumdat:indexingEventSet>
									<!-- 1. EVENTTYPE -->
									<museumdat:eventType>
										Herkunft
									</museumdat:eventType>
									<!-- 2. NO ACTORS-->
									<!-- 3. DATES -->
									<museumdat:indexingDates>
										<xsl:if
											test="exists(child::mpx:datierung/@vonJahr)">

											<museumdat:earliestDate
												museumdat:encodinganalog="mpx:datierung@vonJahr-@vonMonat-@vonTag">
												<xsl:value-of
													select="child::mpx:datierung/@vonJahr" />
												<xsl:if
													test="exists(child::mpx:datierung/@vonMonat)">
													-
													<xsl:value-of
														select="child::mpx:datierung/@vonMonat" />
													<xsl:if
														test="exists(child::mpx:datierung/@vonTag)">
														-
														<xsl:value-of
															select="child::mpx:datierung/@vonTag" />
													</xsl:if>
												</xsl:if>
											</museumdat:earliestDate>
										</xsl:if>

										<xsl:if
											test="exists(child::mpx:datierung/@bisJahr)">
											<museumdat:latestDate
												museumdat:encodinganalog="mpx:datierung@bisJahr-@bisMonat-@bisTag">
												<xsl:value-of
													select="child::mpx:datierung/@bisJahr" />
												<xsl:if
													test="exists(child::mpx:datierung/@bisMonat)">
													-
													<xsl:value-of
														select="child::mpx:datierung/@bisMonat" />
													<xsl:if
														test="exists(child::mpx:datierung/@bisTag)">
														-
														<xsl:value-of
															select="child::mpx:datierung/@bisTag" />
													</xsl:if>
												</xsl:if>
											</museumdat:latestDate>
										</xsl:if>
									</museumdat:indexingDates>

									<!-- 4. LOCATION -->
									<!-- (A und B) oder (A und C) <=> A und (B oder C) -->
									<!-- xsl:if
										test="exists(child::mpx:geogrBezug) and ( . [child::mpx:geogrBezug/@art eq 'Herkunft (Allgemein)'] or exists (not(child::mpx:geogrBezug/@art)))  "
									-->
									<xsl:call-template name="location" />
								</museumdat:indexingEventSet>
							</xsl:if>
						</xsl:if>

						<xsl:if
							test="mpx:verantwortlichkeit eq 'EM-Medienarchiv'">
							<xsl:if
								test="child::mpx:geogrBezug[@funktion = 'Herkunft (Allgemein)']">
								<museumdat:indexingEventSet>
									<!-- 1. EVENTTYPE -->
									<museumdat:eventType>
										Herkunft
									</museumdat:eventType>
									<!-- 2. ACTORS -->
									<xsl:for-each
										select="child::mpx:personKörperschaftRef[@funktion = 'Interpret']|
											    child::mpx:personKörperschaftRef[@funktion = 'Musiker']|
											    child::mpx:personKörperschaftRef[@funktion = 'Leiter']|
											    child::mpx:personKörperschaftRef[@funktion = 'Komponist']">
										<xsl:call-template
											name="indexingActorSet" />
									</xsl:for-each>
									<!-- 3. DATES -->
									<xsl:call-template
										name="DatierungElement">
										<xsl:with-param name="art"
											select="'Aufnahme'" />
									</xsl:call-template>
									<!-- 4. LOCATION -->
									<xsl:call-template name="location" />
								</museumdat:indexingEventSet>
							</xsl:if>
						</xsl:if>


						<!--
							DIE PUBLIKATION
						-->

						<xsl:if
							test="mpx:verantwortlichkeit eq 'EM-Medienarchiv'">
							<!-- TODO
								hier scheint mir eine zweite Bedingung zu fehlen. Im Augenblick erzeuge ich ein Publikationsereignis fuer jeden DS im Medienarchiv.
								Ich sollte aber nur ein solches Ereignis erzeugen, wenn ich Infos dafuer habe.
							-->
							<museumdat:indexingEventSet>
								<!-- 1. EVENTTYPE -->
								<museumdat:eventType>
									Publikation
								</museumdat:eventType>

								<!-- 2. ACTORS -->
								<xsl:for-each
									select="child::mpx:personKörperschaftRef[@funktion = 'Hersteller']|child::mpx:personKörperschaftRef[@funktion = 'Produzent']|child::mpx:personKörperschaftRef[@funktion = 'Vertrieb']">
									<xsl:call-template
										name="indexingActorSet" />
								</xsl:for-each>

								<!--
									3. DATES
									(Fuer Medien ist das Produktionsdatum das Publikationsdatum!)
								-->

								<xsl:call-template
									name="DatierungElement">
									<xsl:with-param name="art"
										select="'Produktion', 'Publikation'" />
									<xsl:with-param name="current"
										select="$currentId" />
								</xsl:call-template>
								<!--
									4 NO LOCATIONS
									I don't think we have the place of publication
								-->
							</museumdat:indexingEventSet>
						</xsl:if>

						<!--
							DAS SAMMELEREIGNIS
							Datierung dazu? Ort dazu?
						-->
						<xsl:if
							test="child::mpx:personKörperschaftRef[@funktion = 'Sammler']">
							<museumdat:indexingEventSet>
								<!-- 1 TYPE	-->
								<museumdat:eventType>
									Sammelereignis
								</museumdat:eventType>

								<!-- 2 ACTORS -->
								<xsl:for-each
									select="child::mpx:personKörperschaftRef[@funktion = 'Sammler']">
									<!-- TODO: not yet tested ... -->
									<xsl:call-template
										name="indexingActorSet" />
								</xsl:for-each>
								<!-- 3 NO DATES (ToDo)-->
								<!-- 4 NO Locations (ToDo)-->
							</museumdat:indexingEventSet>
						</xsl:if>


					</museumdat:indexingEventWrap>

					<!-- RS: maßangabe aus M+ gibt kein Indexing-Element her. Existieren in M+ evtl. aufgeschlüsselte Angaben?
						MM: Bin mir immer noch unsicher, ob dies möglicherweise im Restaurationsmodul der Fall ist. Wir haben
						uns darauf geeinigt, dass das für gegenwärtigem BAM export nicht relevant ist

						TODO: attribute "unit" has to be extracted from mpx-value
						<xsl:if test="exists(child::mpx:maßangabe)">
						<museumdat:indexingMeasurementsWrap>
						<xsl:for-each select="child::mpx:maßangabe">
						<museumdat:indexingMeasurementsSet>
						<museumdat:measurementsSet>
						<xsl:attribute name="museumdat:value">
						<xsl:value-of select="."/>
						</xsl:attribute>

						<xsl:if test="exists(@typ)">
						<xsl:attribute name="museumdat:type">
						<xsl:value-of select="@typ"/>
						</xsl:attribute>
						</xsl:if>
						</museumdat:measurementsSet>
						</museumdat:indexingMeasurementsSet>
						</xsl:for-each>
						</museumdat:indexingMeasurementsWrap>
						</xsl:if>
					-->

					<!-- Hier nun Massangaben fuer Medienarchiv -->
					<xsl:if
						test="child::mpx:verantwortlichkeit ='EM-Medienarchiv'
						and child::mpx:sachbegriff eq 'CD' or 'Schellackplatte' or 'Kassette'
						or 'VCD' or 'DVD' or 'Schallplatte' or 'DAT' or 'Tonband' or 'Video'">
						<museumdat:indexingMeasurementsWrap>
							<museumdat:indexingMeasurementsSet>
								<museumdat:formatMeasurements
									museumdat:encodinganalog="mpx:sachbegriff; mpx:maßangabe; mpx:format">
									<xsl:value-of
										select="child::mpx:sachbegriff" />
								</museumdat:formatMeasurements>
							</museumdat:indexingMeasurementsSet>
						</museumdat:indexingMeasurementsWrap>
					</xsl:if>

					<xsl:if
						test="child::mpx:materialTechnik[@art!='Ausgabe']">
						<museumdat:indexingMaterialsTechWrap>
							<xsl:for-each
								select="child::mpx:materialTechnik[@art!='Ausgabe']">
								<museumdat:indexingMaterialsTechSet>
									<xsl:if test="exists(@art)">
										<xsl:attribute
											name="museumdat:type">
											<xsl:value-of select="@art" />
										</xsl:attribute>
									</xsl:if>
									<museumdat:termMaterialsTech
										museumdat:encodinganalog="mpx:materialTechnik@art">
										<xsl:value-of select="." />
									</museumdat:termMaterialsTech>
								</museumdat:indexingMaterialsTechSet>
							</xsl:for-each>
						</museumdat:indexingMaterialsTechWrap>
					</xsl:if>

					<xsl:if
						test="exists(child::mpx:geogrBezug[@bezeichnung='Ethnie|Kultur|Sprachgruppe'])">
						<museumdat:cultureWrap
							museumdat:encodinganalog="mpx:geogrBezug[@bezeichnung='Ethnie|Kultur|Sprachgruppe']">
							<xsl:for-each
								select="child::mpx:geogrBezug[@bezeichnung='Ethnie|Kultur|Sprachgruppe']">
								<museumdat:culture>
									<xsl:value-of select="." />
								</museumdat:culture>
							</xsl:for-each>
						</museumdat:cultureWrap>
					</xsl:if>
				</museumdat:eventWrap>

				<!--
					V. Element: Beziehungen (Umschlag)
				-->
				<museumdat:relationWrap>
					<museumdat:indexingSubjectWrap>

						<museumdat:indexingSubjectSet>

							<xsl:for-each select="child::mpx:swd">
								<museumdat:subjectTerm
									museumdat:encodinganalog="mpx:swd">
									<xsl:value-of select="." />
								</museumdat:subjectTerm>
							</xsl:for-each>

						</museumdat:indexingSubjectSet>
					</museumdat:indexingSubjectWrap>

					<museumdat:relatedWorksWrap>
						<!--
							*Todo: Aktenverweise oov - Zusamenhänge zu den Akten hätten wir gerne mit deren objId unter
							<relatedWork> V.2.1.1 ID, V.2.1.2 Art der Verwandtschaft ("verwandt mit") und V.2.1.? Link und Label!
						-->
						<xsl:for-each select="child::mpx:oov">
							<museumdat:relatedWorkSet>
								<museumdat:linkRelatedWork
									museumdat:encodinganalog="identNr des verknüpften Objekts(oov)">
									<!-- TODO: provisorisch steht hier die IdentNr anstelle der objId -->
									<xsl:value-of select="." />
								</museumdat:linkRelatedWork>
								<museumdat:relatedWorkRelType
									museumdat:encodinganalog="oov@art">
									<xsl:choose>
										<xsl:when
											test="@art='Vorgang'">
											verwandt mit
										</xsl:when>
										<xsl:when test="@art ne ''">
											<xsl:value-of select="@art" />
										</xsl:when>
									</xsl:choose>
								</museumdat:relatedWorkRelType>
								<xsl:if test="@sachbegriff ne ''">
									<museumdat:labelRelatedWork
										museumdat:encodinganalog="mpx:oov@sachbegriff">
										<xsl:value-of
											select="@sachbegriff" />
									</museumdat:labelRelatedWork>
								</xsl:if>
							</museumdat:relatedWorkSet>
						</xsl:for-each>

					</museumdat:relatedWorksWrap>
				</museumdat:relationWrap>
			</museumdat:descriptiveMetadata>


			<!-- PART TWO
				VI. Element: Administration (Umschlag)
			-->
			<museumdat:administrativeMetadata>
				<museumdat:rightsWork
					museumdat:encodinganalog="mpx:credits">
					<!--  TODO: M+Credits AND M+Rechte not yet exported! -->
					<xsl:value-of select="credits" />
				</museumdat:rightsWork>

				<museumdat:recordWrap>
					<museumdat:recordID
						museumdat:encodinganalog="mpx:objId">
						<xsl:value-of select="$currentId" />
					</museumdat:recordID>

					<!--
						TODO: FIX For the time being, I asssume the everything is
						on object level.
					-->

					<!--  Vokabular? -->
					<museumdat:recordType>
						Einzelobjekt
					</museumdat:recordType>

					<!-- Es kann nur eine geben: verwaltendeInstitution 18.3.2008-->
					<xsl:choose>
						<xsl:when test="mpx:verwaltendeInstitution">
							<museumdat:recordSource
								museumdat:encodinganalog="mpx:verwaltendeInstitution">
								<xsl:value-of
									select="mpx:verwaltendeInstitution" />
							</museumdat:recordSource>
						</xsl:when>
						<xsl:otherwise>
							<!-- wenn keine verwaltendendeInstitution angegeben, wird verkehrtes mdat erzeugt! -->
							<museumdat:recordSource
								museumdat:encodinganalog="mpx:verwaltendeInstitution">
								keine verwaltende Institution angegeben
							</museumdat:recordSource>
						</xsl:otherwise>
					</xsl:choose>

					<museumdat:recordInfoSet>
						<xsl:comment>
							museumdat:recordinfoID/museumdat:recordinfoLink
							could/should be created by BAM etc.
						</xsl:comment>

						<museumdat:recordMetadataDate
							museumdat:encodinganalog="mpx:bearbDatum">
							<xsl:value-of
								select="child::mpx:bearbDatum" />
						</museumdat:recordMetadataDate>
					</museumdat:recordInfoSet>
				</museumdat:recordWrap>


				<museumdat:resourceWrap>
					<!-- Kann man child::mpx:abbildungen irgendwie auf museumDat mappen?-->
					<xsl:for-each
						select="/mpx:museumPlusExport/mpx:multimediaobjekt[mpx:verknüpftesObjekt=$currentId]">
						<xsl:if
							test="contains (mpx:multimediaFotoNegNr,'BAM')">
							<museumdat:resourceSet>
								<museumdat:linkResource
									museumdat:encodinganalog="mpx:multimediaPfadangabe\mpx:multimediaDateiname.mpx:multimediaErweiterung">
									<xsl:attribute name="museumdat:type"
										select="mpx:multimediaFunktion" />
									<xsl:value-of
										select="concat (mpx:multimediaPfadangabe,'\',mpx:multimediaDateiname,'.',mpx:multimediaErweiterung)" />
								</museumdat:linkResource>
								<museumdat:resourceID
									museumdat:encodinganalog="mpx:multimediaobjekt@mulId">
									<xsl:value-of select="@mulId" />
								</museumdat:resourceID>
								<museumdat:resourceRelType
									museumdat:encodinganalog="xslt">
									für BAM ausgewähltes Foto
								</museumdat:resourceRelType>
								<xsl:if
									test="exists(mpx:multimediaTyp)">
									<museumdat:resourceType
										museumdat:encodinganalog="mpx:multimediaPfadangabe">
										<xsl:choose>
											<xsl:when
												test="exists(mpx:multimediaPfadangabe)">
												Digitale Aufnahme
											</xsl:when>
											<xsl:otherwise>
												<xsl:value-of
													select="mpx:multimediaTyp" />
											</xsl:otherwise>
										</xsl:choose>
									</museumdat:resourceType>
								</xsl:if>
								<xsl:if
									test="exists(mpx:multimediaInhaltAnsicht)">
									<museumdat:resourceViewType
										museumdat:encodinganalog="mpx:multimediaInhaltAnsicht">
										<xsl:value-of
											select="mpx:multimediaInhaltAnsicht" />
									</museumdat:resourceViewType>
								</xsl:if>
								<xsl:if
									test="exists(mpx:multimediaUrhebFotograf)">
									<museumdat:resourceSource
										museumdat:encodinganalog="mpx:multimediaUrhebFotograf"
										museumdat:type="Urheber / Fotograph">
										<xsl:value-of
											select="mpx:multimediaUrhebFotograf" />
									</museumdat:resourceSource>
								</xsl:if>
							</museumdat:resourceSet>
						</xsl:if>
					</xsl:for-each>
				</museumdat:resourceWrap>
			</museumdat:administrativeMetadata>
		</museumdat:museumdat>
	</xsl:template>

	<!--
		FUNKTIONEN DIE AUS DEN INDEXINGeVENTS AUFGERUFEN WERDEN
	-->

	<xsl:template name="indexingActorSet">
		<xsl:variable name="Name" select="." />
		<museumdat:indexingActorSet>
			<museumdat:nameActorSet>
				<museumdat:nameActor>
					<!-- Soll ich das erste Vorkommnis nehmen oder die Funktion? -->
					<xsl:attribute name="museumdat:encodinganalog">
						<xsl:value-of
							select="'mpx:personKörperschaftRef'" />
					</xsl:attribute>
					<xsl:if test="position()=1">
						<xsl:attribute name="museumdat:pref">
							<xsl:value-of select="'preferred'" />
						</xsl:attribute>
					</xsl:if>
					<xsl:choose>
						<xsl:when
							test="mpx:personKörperschaft/mpx:typ = 'Person' or 'Künstler'">
							<xsl:attribute name="museumdat:type">
								<xsl:value-of select="'personalName'" />
							</xsl:attribute>
						</xsl:when>
						<xsl:when
							test="mpx:personKörperschaft/mpx:typ = 'Körperschaft' or 'Sozietät' or 'Vertrieb'">
							<xsl:attribute name="museumdat:type">
								<xsl:value-of select="'corporateName'" />
							</xsl:attribute>
						</xsl:when>
						<!-- sonst schreib lieber gar nichts hin! -->
					</xsl:choose>
					<xsl:value-of select="$Name" />
				</museumdat:nameActor>
				<xsl:if
					test="/mpx:museumPlusExport/mpx:personKörperschaft[mpx:name=$Name]/mpx:quelle">
					<museumdat:sourceNameActor
						museumdat:encodinganalog="mpx:personKörperschaft/quelle">
						<xsl:value-of
							select="/mpx:museumPlusExport/mpx:personKörperschaft[mpx:name=$Name]/mpx:quelle" />
					</museumdat:sourceNameActor>
				</xsl:if>
			</museumdat:nameActorSet>
			<xsl:if
				test="/mpx:museumPlusExport/mpx:personKörperschaft[mpx:name=$Name]/mpx:nationalität">
				<museumdat:nationalityActor
					museumdat:encodinganalog="mpx:personKörperschaft/nationalität">
					<xsl:value-of
						select="/mpx:museumPlusExport/mpx:personKörperschaft[mpx:name=$Name]/mpx:nationalität" />
				</museumdat:nationalityActor>
			</xsl:if>
			<xsl:if
				test="/mpx:museumPlusExport/mpx:personKörperschaft[mpx:name=$Name]/mpx:datierung[@art='Lebensdaten']">
				<museumdat:vitalDatesActor
					museumdat:encodinganalog="mpx:personKörperschaft/datierung[@art='Lebensdaten']">
					<xsl:value-of
						select="/mpx:museumPlusExport/mpx:personKörperschaft[mpx:name=$Name]/mpx:datierung[@art='Lebensdaten']" />
				</museumdat:vitalDatesActor>
			</xsl:if>
			<museumdat:roleActor
				museumdat:encodinganalog="mpx:personKörperschaft/@funktion">
				<xsl:value-of select="$Name/@funktion" />
			</museumdat:roleActor>
		</museumdat:indexingActorSet>
	</xsl:template>

	<xsl:template name="DatierungElement">
		<!--
			Diese "Funktion" erwartet das Datum im Element Datierung, wo auch eine verbale Datierung stehen
			koennte und nicht in den Attributen vonJahr etc. Ich halte das fuer eine korrekte Eingabe in M+
			Deswegen fixe ich es nicht!

			Uebergabe Parameter eine Sequence von Werten, auf die getestet werden soll!
			z.B. xsl:with-param name="art" select="'Produktion', 'Publikation'" /
		-->
		<xsl:param name="art" />
		<xsl:param name="current" />
		<!--
			18.3.08Ich kann mir dieses if anscheinend sparen, da es auch in der folgenden for-each enthalten ist!
			<xsl:if test="mpx:datierung[@art = $art]">
			Dieses if "personalisiert" die Funktion, so dass sie nur fuer den
			als Param uebergebenen Qualifikator funktioniert.
			Wenn ich nur mpx:datierung[@art = $art] teste, scheint es nur manchmal zu funktionieren.
		-->

		<!-- Fuer den Fall, dass es mehr als ein Datierungseelment gibt! -->
		<xsl:for-each-group select="mpx:datierung[@art = $art]"
			group-by=".">
			<!-- Ich bin nicht sicher, ob = testet, ob @art ein Element aus der Sequence enthaelt oder alle! -->
			<xsl:sort data-type="number" />
			<xsl:if test="position()=1 and number()">
				<xsl:variable name="early" select="." />
				<xsl:if test="position()=last()">
					<museumdat:indexingDates>
						<museumdat:earliestDate
							museumdat:encodinganalog="mpx:datierung[@art = {$art}]">
							<xsl:value-of select="$early" />
						</museumdat:earliestDate>
						<museumdat:latestDate
							museumdat:encodinganalog="mpx:datierung[@art = {$art}]">
							<xsl:value-of select="." />
						</museumdat:latestDate>
					</museumdat:indexingDates>
				</xsl:if>
			</xsl:if>
		</xsl:for-each-group>
	</xsl:template>

	<xsl:template name="location">
		<museumdat:indexingLocationWrap>
			<xsl:for-each
				select="child::mpx:geogrBezug[@funktion = 'Herkunft (Allgemein)']">
				<xsl:if test="@bezeichnung != 'Ethnie|Kultur'">
					<xsl:element name="museumdat:indexingLocationSet">
						<xsl:if test="@bezeichnung">
							<xsl:choose>
								<xsl:when
									test="contains('Insel|Tal|Gebirge|Insel|Inselgruppe|Kontinent|Kontinentteil|See',@bezeichnung)">
									<xsl:attribute
										name="museumdat:geographicalEntity">
										<xsl:value-of
											select="@bezeichnung" />
									</xsl:attribute>
								</xsl:when>
								<xsl:when
									test="contains('Bundesstaat|Distrikt|Dorf|Distrikt|Land|Provinz|Region|Stadt',@bezeichnung)">
									<xsl:attribute
										name="museumdat:politicalEntity">
										<xsl:value-of
											select="@bezeichnung" />
									</xsl:attribute>
								</xsl:when>
								<!-- wenn etwas Unbekanntes, dann lieber nichts schreiben! -->
							</xsl:choose>
						</xsl:if>
						<museumdat:nameLocationSet>
							<museumdat:nameLocation
								museumdat:encodinganalog="mpx:geogrBezug">
								<xsl:value-of select="." />
							</museumdat:nameLocation>
						</museumdat:nameLocationSet>
					</xsl:element>
				</xsl:if>
			</xsl:for-each>
		</museumdat:indexingLocationWrap>
	</xsl:template>

</xsl:stylesheet>
