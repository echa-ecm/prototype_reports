<?xml version="1.0" encoding="UTF-8"?>

<#-- contents of example -->
<#-- initialise main variables -->
<#-- import common modules -->
<#-- use default front cover -->
<#-- get root entity's name -->
<#-- get structural formula image using *macros_common_general.ftl (substance only) -->
<#-- iterate composition endpoint (substance only) and fetch coposition general name) -->
<#-- get first composition endpoint only (substance only) and fetch coposition name and uuid) -->
<#-- **TO DO** get category member content from the root entity that is a member of that category -->
<#-- get the traversal macro and use it to output a list (of reliability scores) -->



<#-- Import common macros and functions -->
<#import "traversal_utils.ftl" as utils>
<#import "macros_common_general.ftl" as com>
<#import "front_page_list_reports.ftl" as fp>
<#import "common_module_environmental_hazard_assessment.ftl" as keyEnvironmentalHazardAssessment>
<#import "macros_common_studies_and_summaries.ftl" as studyandsummaryCom>

<!-- Initialize common variables -->
<@com.initializeMainVariables/>	

<!-- Example template file -->
<#assign locale = "en" />
<book version="5.0" xmlns="http://docbook.org/ns/docbook" xmlns:xi="http://www.w3.org/2001/XInclude">

	<#-- standard front page structure (note that tags *info *title *cover are mandatory)
	<info>
        <title>This is my example title</title>
		<cover>
            <para>
				This is some info on the cover page
			</para>
        </cover>
    </info>
	-->

	<#-- Get default front page -->
	<@fp.getFrontPage _subject _dossierHeader "my example front page"/>
	
	<!-- Part A -->
	<part>
		<title>First part of the document (if needed)</title>
		
		<#-- each chapter is nested inside a *part - note that *part is optional -->
		<chapter label="1">
			<title role="HEAD-1">First Chapter</title>
			<para>

			<#--------------------------------------------------------------------->
			<#-- use the root entity's document type to output root entity names -->
			<#--------------------------------------------------------------------->

				<#if isSubstance(_subject)>
				Substance name:  <@com.text _subject.ChemicalName/>

					<#elseif isMixture(_subject)>
					Mixture name: <@com.text _subject.MixtureName/>

						<#elseif isCategory(_subject)>
						Category name: <@com.text _subject.CategoryName/>

				</#if>

			</para>

			<#if isSubstance(_subject)>	
			<para>
				<#------------------------------------------------------------------------------>
				<#-- extract the structural formula from the substance's reference substance --->
				<#-- This uses a path to the reference substance reference and a common macro -->
				<#------------------------------------------------------------------------------>
				
				<@com.structuralFormula com.getReferenceSubstanceKey(_subject.ReferenceSubstance.ReferenceSubstance) 100 true/>			
			</para>
			</#if>
			
			<#---------------------------------------------------------------------------->
			<#-- Chapter to show iteration of a composition endpoint and its documents --->
			<#---------------------------------------------------------------------------->

			<#if isSubstance(_subject)>

				<#assign compositionList = iuclid.getSectionDocumentsForParentKey(_subject.documentKey, "FLEXIBLE_RECORD", "SubstanceComposition") />
				
				<#if compositionList?has_content>
				<#assign compositionRecord = compositionList[0] />

					<table border="1">
						<title>Example table</title>
						<col width="100%" />
						<tbody>
							<tr>
								<th><emphasis role="bold">Composition name</emphasis></th>
							</tr>

							<#-- iterate composition documents with Freemarker #List directive --->
							<#-- a new table row (TR) will appear for every compositon document -->
							<#list compositionList as composition>							
								<tr>
									<td>
										<#-- composition general information name extraction -->
										<@com.text composition.GeneralInformation.Name/>
									</td>
								</tr>
							</#list>

								<tr>
									<td>
										<#-- first composition only -->
										<para>First composition name: <@com.text compositionRecord.name/></para>
										<para>First composition uuid: <@com.text compositionRecord.documentKey.uuid/></para>
										
									</td>
								</tr>

						</tbody>
					</table>
				</#if>
			</#if>

		</chapter>
		
		<#if isSubstance(_subject) || isMixture(_subject)>
		<chapter label="2">
		
			<title role="HEAD-1">Second chapter - import an environmental hazard study out of the box</title>
			
			<section>
				<title role="HEAD-4">Long-term toxicity to aquatic invertebrates</title>
				<@keyEnvironmentalHazardAssessment.longTermToxicityToAquaticInvertebratesStudies _subject/>	
			</section>
		
		</chapter>
		</#if>

		<#-- Define the main macro to be used to retrieve output by the traversal approach -->
		<#assign mainMacroName = "printIfDocumentTypeIsEndpointStudyRecord"/>
		<#assign mainMacroArgs = ['docElementNode', 'sectionNode', 'entityDocument' 'level']/>

		<#-- Make global the macroCall as well as each macro used in it -->
		<#global mainMacroCall="<@" + mainMacroName + " " + mainMacroArgs?join(" ") + "/>"/>
		<#global printIfDocumentTypeIsEndpointStudyRecord = printIfDocumentTypeIsEndpointStudyRecord/>
		<#global printListOfReliabilityScores = printListOfReliabilityScores/>
		<#global tableOutput=tableOutput/>

		<#-- Counter of list items -->
		<#assign index=0/>

		<#if isSubstance(_subject) || isMixture(_subject)>

		<chapter label="1">
        <title role="HEAD-1">Listing through the IUCLID tree</title>

			<para role="small">

				<#-- Table header -->
				<table border="1">
					<title>Reliability scores</title>

					<col width="10%" />
					<col width="40%" />
					<col width="50%" />

					<tbody>
					<tr>
						<th colspan="1"><?dbfo bgcolor="#d6eaf8" ?><emphasis role="bold">Count studies</emphasis></th>
						<th colspan="1"><?dbfo bgcolor="#d6eaf8" ?><emphasis role="bold">Endpoint name</emphasis></th>
						<th colspan="1"><?dbfo bgcolor="#d6eaf8" ?><emphasis role="bold">Reliability</emphasis></th>
					</tr>

					<#-- Traversal approach: prints one row per claim -->
					<@utils.traversal _subject 8/>

					</tbody>
				</table>
			</para>

  		</chapter>
		
		</#if>

	</part>

</book>


<#-- Macros and functions -->

<#-------------------------------------------->
<#---- Condition the output ------------------>
<#-------------------------------------------->
<#macro printIfDocumentTypeIsEndpointStudyRecord docElementNode sectionNode entityDocument level>
    
<#if level==0>

	<#-- section document key *sectionDoc-->
	<#local sectionDoc = docElementNode?root>

		<#---- Only doc.type ENDPOINT_STUDY_RECORD --->		
		<#---- Only if reliability has content ------->
		<#if sectionDoc.documentType=="ENDPOINT_STUDY_RECORD" && sectionDoc.AdministrativeData.Reliability?has_content>
        	<@printListOfReliabilityScores docElementNode sectionDoc sectionNode entityDocument/>
		</#if>
</#if>

</#macro>

<#macro printListOfReliabilityScores fieldNode sectionDoc sectionNode entityDocument>

	<#-- get index count number -->    
    <#assign index=index+1/>

	<#-- Get section name and number of the selected working context -->
	<#local sectionName = "">
	<#if sectionNode?has_content>
		<#if sectionNode.number?has_content>
			<#local sectionName = sectionNode.number + " ">
		</#if>
		<#local sectionName = sectionName + sectionNode.title>
	</#if>
		
	<#-- Get the web URL pointing to the document -->
	<#assign docUrl=utils.getDocumentUrl(sectionDoc) />

	<#-- Provide the rest of the table (tr) and (td) matching the table properties outlined above -->
	<@tableOutput entityDocument sectionName sectionDoc docUrl  />

</#macro>

<#macro tableOutput entityDocument sectionName sectionDoc docUrl >
    <tr>
		
		<#-- Index -->
        <td>
            ${index}
        </td>

	    <#-- Endpoint name -->
        <td>
            <@com.text sectionName />
        </td>

        <#-- Reliability -->
        <td>
			<#if sectionDoc.documentType=="ENDPOINT_STUDY_RECORD">
				<#if sectionDoc.AdministrativeData.Reliability?has_content>	

					<#-- get hyperlink back to document where reliability is found -->
					<ulink url="${docUrl}">		
						<#-- get reliability -->
						<@com.picklist sectionDoc.AdministrativeData.Reliability />
					</ulink>
				</#if>
			</#if>
		
        </td>
	</tr>
</#macro>

<#-- functions to check root entity type -->
<#function isSubstance _subject>
<#if _subject.documentType=="SUBSTANCE">
	<#return true>
<#else>
	<#return false>
</#if>
	<#return false>
</#function>

<#function isMixture _subject>
<#if _subject.documentType=="MIXTURE">
	<#return true>
<#else>
	<#return false>
</#if>
	<#return false>
</#function>

<#function isCategory _subject>
<#if _subject.documentType=="CATEGORY">
	<#return true>
<#else>
	<#return false>
</#if>
	<#return false>
</#function>


