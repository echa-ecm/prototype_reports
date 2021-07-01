
<#assign tableKindToName = {'ROOT': 'Mixture', 'ACTIVE': 'Active substance', 'NON_ACTIVE': 'Non-active component', 'DISTANT_DESCENDANTS': 'Sub-entity'}>
<#assign tableKindToColor = {'ROOT': 'green', 'ACTIVE': 'purple', 'NON_ACTIVE': 'olive', 'DISTANT_DESCENDANTS':  'blue'}>
<#assign entityToName = {'SUBSTANCE': 'substance', 'MIXTURE': 'mixture', 'TEMPLATE': 'template'}>
<#assign documentPathColl = ''>

<#function generateChapterTitle tableKind rootType>
  <#if tableKind == TABLE.ROOT>
    <#return 'Main ${entityToName[rootType]}'>
  <#elseif tableKind == TABLE.ACTIVE>
    <#return 'Active substance'>
  <#elseif tableKind == TABLE.NON_ACTIVE>
    <#return 'Other components'>
  <#elseif tableKind == TABLE.DISTANT_DESCENDANTS>
    <#return 'Mixture-in-mixture components'>
  </#if>
  <#stop 'Unknown table type: ' + tableKind>
</#function>

<#function generateTableTitle tableKind rootType>
  <#if tableKind == TABLE.ROOT>
    <#return 'Annotations on: '>
  <#elseif tableKind == TABLE.ACTIVE>
    <#return 'Annotations on active substance mixture component: '>
  <#elseif tableKind == TABLE.NON_ACTIVE>
    <#return 'Annotations on other mixture components: '>
  <#elseif tableKind == TABLE.DISTANT_DESCENDANTS>
    <#return 'Annotations on mixture-in-mixture components'>
  </#if>
  <#stop 'Unknown table type: ' + tableKind>
</#function>

<#-------------------------------------------------->
<#-- Main template file for a list of Annotations -->
<#-------------------------------------------------->
<#macro annotationsChapter entityTablesHash chapterNum tableKind rootType>
  <#compress>
    <chapter label='${chapterNum}'>
      <title role='HEAD-1'>${generateChapterTitle(tableKind, rootType)}</title>
      <#list entityTablesHash?keys as entityName>
        <#local isSingleton = (entityName == SINGLETON_IND)>
        <#local tableTitle = generateTableTitle(tableKind, rootType) + isSingleton?string('', ' [${entityName}]')>
        <#local entityAnnotGroup = entityTablesHash[entityName]>
          <table border='1'>
            <title>${tableTitle}</title>
            <col width='40%' />
            <col width='60%' />
            <tbody>
              <tr>
                <th><?dbfo bgcolor='#C6C9F0' ?><emphasis role='bold'>Document details</emphasis></th>
                <th><?dbfo bgcolor='#C6C9F0' ?><emphasis role='bold'>Annotation details</emphasis></th>
              </tr>

              <#list entityAnnotGroup as annotation>
                <@tableRowForAnnotations annotation tableKind/>
              </#list>
              ${documentPathColl}
            </tbody>
          </table>
      </#list>
    </chapter>
  </#compress>
</#macro>

<#macro columnRecord description content>
  <para><emphasis role='bold'>${description}:</emphasis> ${content}</para>
</#macro>


<#macro generalDocumentDetails annotation tableKind isBPR=false>
  <#local document = annotation.sectionDoc>
  <#local sectionName = annotation.sectionName>
  <#local sectionDocType = annotation.sectionDocType>
  <#local documentName = annotation.entityName>
  <#local documentUUID = annotation.docID.uuid>
  <#local dossierUUID = annotation.docID.snapshotUuid>
  <#local rootUUID = annotation.entityID.uuid>
  <#assign historyList = (getFirstHistoryOnlyOfDocument(document))!'' />
  <#if historyList?has_content>
    <@columnRecord 'Last updated' historyList.date/>
  </#if>

  <para>
    <emphasis role='bold'>Document UUID of the
      <#if TABLE[tableKind]??>
        <phrase role='${tableKindToColor[tableKind]}'><@com.text tableKindToName[tableKind]/>:</phrase>
      </#if>
    </emphasis>
    <#assign docUrl=iuclid.webUrl.documentView(document.documentKey) />
    <#if docUrl?has_content>
      <ulink url='${docUrl}'><@com.text documentUUID /></ulink>
    <#else>
      <@com.text documentUUID />
    </#if>
  </para>

  <#if sectionName != LEVELNAME.COMPOSITE_ENTITY && isBPR>
    <para><emphasis role='bold'>Annex II/III requirement: </emphasis><@com.text SECTION_TO_ANNEX_REQUIREMENT[sectionName]!'None' /></para>
  </#if>
  <para><emphasis role='bold'>Section Number:</emphasis>${annotation.sectionNumber}</para>
  <para><emphasis role='bold'>Section Name:</emphasis>${sectionName}</para>

  <#if sectionDocType == 'ENDPOINT_STUDY_RECORD'>
    <@dataWaivingComparisonDocument annotation/>
    <@reliabilityComparisonDocument annotation/>
  </#if>
</#macro>

<#macro annotationsLayoutSubstance reportData rootType>
  <book version='5.0' xmlns='http://docbook.org/ns/docbook' xmlns:xi='http://www.w3.org/2001/XInclude'>
    <#list reportData?keys as chapterKey>
      <#local chapterHash = reportData[chapterKey]>
      <@produceChapter chapterHash rootType chapterKey 1/>
    </#list>
  </book>
</#macro>

<#macro produceChapter chapterHash rootType chapterKey chapterNum>
  <#-- Exclude chapter if there are no relevant annotations (sequential chapter numbers) -->

  <#if chapterHash?size != 0>
    <@annotationsChapter
      chapterHash
      chapterNum
      chapterKey
      rootType
    />
  </#if>
</#macro>

<#macro annotationsLayoutMixture reportData rootType>
  <#compress>
    <book version='5.0' xmlns='http://docbook.org/ns/docbook' xmlns:xi='http://www.w3.org/2001/XInclude'>
      <#local chapterNum = 1>
      <#list reportData?keys as chapterKey>
        <#local chapter = reportData[chapterKey]>
        <@produceChapter chapter rootType chapterKey chapterNum/>
        <#local chapterNum = chapterNum + 1>
      </#list>
    </book>
  </#compress>
</#macro>

<#macro tableRowForAnnotations annotation tableKind>
  <#local documentName=annotation.entityName>
  <#local documentUUID=annotation.docID.uuid>
  <#local dossierUUID=annotation.docID.snapshotUuid>
  <#local rootUUID=annotation.entityID.uuid>

  <#compress>

    <tr>
      <td><?dbfo bgcolor='#D1EEF5' ?>
        <#if tableKind == TABLE.ACTIVE>
          <@activeSubstanceDocumentDetails annotation/>
        </#if>
        <#if tableKind == TABLE.NON_ACTIVE>
          <@nonActiveSubstanceDocumentDetails annotation/>
        </#if>
        <#if tableKind == TABLE.DISTANT_DESCENDANTS>
          <@distantDescendantsDocumentDetails annotation/>
        </#if>
        <@generalDocumentDetails annotation tableKind/>
      </td>
      <td>

        <#if annotation.historyList?has_content>
          <para>Annotation name: <emphasis role='bold'><phrase role='blue'>${annotation.name}</phrase></emphasis></para>

          <#if annotation.type?has_content>
            Annotation type: <@com.picklist annotation.type />
          </#if>

          <para>Annotation has data protection flag: ${annotation.confidentiality?string('yes', 'no')}</para>

          <para><emphasis role='bold'>UUID of the annotation: </emphasis>${annotation.key}</para>
          <para><emphasis role='bold'>Last updated: </emphasis>${annotation.historyList.date}</para>
        </#if>
        <#if annotation.sectionDocType == 'ENDPOINT_STUDY_RECORD'>
          <@annotationApplicantsSummary annotation/>
            <#attempt>
              <@dataWaivingComparisonAnnotation annotation/>
              <@reliabilityComparisonAnnotation annotation/>
              <#recover>
            </#attempt>
        </#if>
      </td>
    </tr>

  </#compress>
</#macro>

<#macro entityNameDetailRecords annotation>
  <#local entityName = entityToName[annotation.entityType]>
  <@columnRecord (entityName?capitalize + ' name') annotation.entityName/>
</#macro>

<#macro activeSubstanceDocumentDetails annotation>
  <@entityNameDetailRecords annotation/>
</#macro>

<#macro distantDescendantsDocumentDetails annotation>
  <@entityNameDetailRecords annotation/>
</#macro>

<#macro nonActiveSubstanceDocumentDetails annotation>
  <@entityNameDetailRecords annotation/>
  <#local entityFunction = annotation.entityFunction>
  <#if entityFunction?has_content>
    <@columnRecord 'Function' entityFunction/>
  </#if>
</#macro>


<#macro annotationNameOfAuthority annotation>
  <#compress>
    <#attempt>
		  <#if annotation.authority>
		    ${annotation.authority}
			  <#else/>
			  No Authority or Organisation name is provided for this annotation
		  </#if>
	    <#recover>
	      [No Access]
    </#attempt>
  </#compress>
</#macro>

<#macro annotationApplicantsSummary annotation>
<#compress>
  <#local authority = (annotation.authority)!>
  <#local agreement = (annotation.agreement)!>
	<#attempt>
		<#if agreement?has_content>
			<#if annotation?has_content>
				<#if authority?has_content>
					<para>The evaluating authority: <emphasis role="bold"><phrase role="blue"><@annotationNameOfAuthority annotations/></phrase></emphasis> agrees with the applicant's summary</para>
				<#elseif !(authority)?has_content>
					<para>The evaluating authority agrees with the applicant's summary</para>
				</#if>
			</#if>
		</#if>

		<#if agreement == 'yes'>
			<#if annotation?has_content>
				<#if authority?has_content>
					<para>The evaluating authority: <emphasis role="bold"><phrase role="blue"><@annotationNameOfAuthority annotations/></phrase></emphasis> disagrees with the applicant's summary</para>
				<#elseif !(authority)?has_content>
					<para>The evaluating authority disagrees with the applicant's summary</para>
				</#if>
			</#if>
		</#if>

		<#if com.picklistValueMatchesPhrases(annotation.EvalInfo.AgreementWithApplicantsSummary, ["not specified"])>
			<#if annotation?has_content>
				<#if authority?has_content>
					<para>The evaluating authority: <emphasis role="bold"><phrase role="blue"><@annotationNameOfAuthority annotations/></phrase></emphasis> has 'not specified' whether there is agreement with the applicant's summary</para>
				<#elseif !(authority)?has_content>
					<para>The evaluating authority has 'not specified' whether there is agreement with the applicant's summary</para>
				</#if>
			</#if>
		</#if>

		<#recover>
		[No Access]
	</#attempt>
</#compress>
</#macro>

<#macro dataWaivingComparisonDocument annotation>
<#compress>
  <#local document = annotation.entityDoc>
  <#if document?has_content>
    <#local dataWaivingInEndpointStudyRecord = document.AdministrativeData.DataWaiving />
    
    <#local dataWaivingJustificationInEndpointStudyRecord = document.AdministrativeData.DataWaivingJustification />
    
    <#assign annotationDataWaiving><@annotationDatasetDataWaiving annotations/></#assign>
    
    <#if dataWaivingInEndpointStudyRecord?has_content && annotationDataWaiving?has_content>		
      <para><emphasis role="bold">Data Waiving information in document</emphasis></para>
      <para>Data waiving provided in the record: <phrase role="blue"><@com.text documentName /></phrase> according to the <phrase role="orange">applicant</phrase> is:</para>
      <para role="indent">
        <@com.picklist dataWaivingInEndpointStudyRecord />
        <@picklistMultipleSpecialBulletPoints dataWaivingJustificationInEndpointStudyRecord />
      </para>	
    </#if>
  </#if>
</#compress>
</#macro>

<#macro dataWaivingComparisonAnnotation annotation>
<#compress>
  <#local document = annotation.entityDoc>
<#if document?has_content>

		<#local dataWaivingInEndpointStudyRecord = document.AdministrativeData.DataWaiving />
		
		<#local dataWaivingJustificationInEndpointStudyRecord = document.AdministrativeData.DataWaivingJustification />
		
		<#assign annotationDataWaiving><@annotationDatasetDataWaiving annotations/></#assign>
		
		<#if dataWaivingInEndpointStudyRecord?has_content && annotationDataWaiving?has_content>		
		
			<#if annotationDataWaiving?has_content>
			<para><emphasis role="bold">Data Waiving evaluation in the annotation</emphasis></para>
			<para>Data waiving evaluation according to the <phrase role="orange">authority</phrase> for the record: <phrase role="blue"><@com.text documentName /></phrase> is:</para>
				<para role="indent">			
					<@annotationDatasetDataWaiving annotation/>
				</para>				
			</#if>
		</#if>
		
	
</#if>
</#compress>
</#macro>

<#macro reliabilityComparisonDocument annotation>
  <#compress>
    <#local document = annotation.entityDoc>
    <#local documentName = annotation.entityName>
    <#if document?has_content>
      <#local documentPath = annotation.docType />
        <#local reliability = document.AdministrativeData.Reliability />
        <#local reliabilityRationale = document.AdministrativeData.RationalReliability />
        <#assign annotationReliability><@annotationDatasetReliability annotations/></#assign>
        <#if reliability?has_content && annotationReliability?has_content>
          <para><emphasis role="bold">Reliability information in document</emphasis></para>
          <para>Reliability of study for the record: <phrase role="blue"><@com.text documentName /></phrase> according to the <phrase role="orange">applicant</phrase> is:</para>
          <para role="indent">
            <para><emphasis role="bold">Reliability:</emphasis> <@com.picklist reliability /></para>
            <#if reliabilityRationale?has_content>
              <para><emphasis role="bold">Rationale:</emphasis> <@com.picklist reliabilityRationale /></para>
            </#if>
          </para>
        </#if>
      
    </#if>
  </#compress>
</#macro>

<#macro reliabilityComparisonAnnotation annotation>
  <#compress>
    <#local document = annotation>
    <#local documentName = annotation.entityName>
    <#if document?has_content>
      <#stop 'test'>
      <#local documentPath = annotationIdentifier.docType />
      <#assign documentPathColl = documentPathColl + documentPath>
        <#local reliability = document.AdministrativeData.Reliability />

        <#local reliabilityRationale = document.AdministrativeData.RationalReliability />

        <#assign annotationReliability><@annotationDatasetReliability annotations/></#assign>

        <#if reliability?has_content && annotationReliability?has_content>
          <para><emphasis role="bold">Reliability evaluation in the annotation</emphasis></para>
          <para>Reliability of study for the record: <phrase role="blue"><@com.text documentName /></phrase> according to the <phrase role="orange">evaluating authority</phrase> is:</para>
          <para role="indent">
            <@annotationDatasetReliability annotations/>
          </para>
		    </#if>
	    </#if>
  </#compress>
</#macro>

<#macro annotationDatasetDataWaiving annotation>
  <#compress>
    <@com.picklist annotation.isWaiverable/>
  </#compress>
</#macro>

<#macro annotationDatasetReliability annotation>
<#compress>
  <#if annotation?has_content>
  <@com.picklist annotation.EvalInfo.Reliability/>
  </#if>
</#compress>
</#macro>
<#macro annotationDatasetRemarks annotation>
<#compress>
  <#if annotation?has_content>
  <@com.text annotation.EvalInfo.Remarks/>
  </#if>
</#compress>
</#macro>
<#macro annotationDatasetCrossReference annotation>
<#compress>
  <#if annotation?has_content>
  <@com.text annotation.EvalInfo.CrossReferenceToOtherStudy/>
  </#if>
</#compress>
</#macro>

<#macro annotationDatasetConclusions annotation>
<#compress>
  <#if annotation?has_content>
  <@com.text annotation.EvalInfo.Conclusions/>
  </#if>
</#compress>
</#macro>

<#macro annotationDatasetExecSummary annotation>
<#compress>
  <#if annotation?has_content>
  <@com.richText annotation.EvalInfo.ExecutiveSummary/>
  </#if>
</#compress>
</#macro>

<#macro annotationUUID annotation>
<#compress>
<#attempt>
  <#if annotation?has_content>
  <@com.text annotation.documentKey.uuid/>
  </#if>
  <#recover>
  [No Access]
</#attempt>
</#compress>
</#macro>
