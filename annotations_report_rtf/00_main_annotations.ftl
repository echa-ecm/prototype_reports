<#include '10_constants.ftl'>
<#import '20_customization.ftl' as custom>
<#import '30_utils.ftl' as utils>
<#import '40_traversal.ftl' as traversal>
<#import '50_layout_rtf.ftl' as layout_rtf>
<#import '51_layout_csv.ftl' as layout_csv>
<#import 'macros_common_general.ftl' as com>

<#-- introduced in FreeMarker 2.3.24 -->
<#-- <#assign output_extension = custom.output_extension!(.output_format)> -->

<#assign output_extension = custom.output_extension!>

<#-- Initialize the following variables:
	* _dossierHeader (:DossierHashModel) //The header document of a proper or 'raw' dossier, can be empty
	* _subject (:DocumentHashModel) //The dossier subject document or, if not in a dossier context, the root document, never empty
	-->
<@com.initializeMainVariables/>

<#assign layoutMetadata = {
  'dossier' : _dossierHeader!,
  'subject' : _subject,
  'columnsOrdered' : layout_csv.reportTableProperties?keys
}>


<#assign rootEntity = entity.root>
<#assign rootSubject = com.getReportSubject(rootDocument)>
<#assign rootType = rootSubject.documentType>
<#assign rootName = rootDocument.name>
<#assign rootComponentFunctionHash = {}>

<#-- entityDocument is level=0 document or first document found when traversing -->
<#function collectDocumentHash sectionDoc entityDocument sectionNode level isDocument>
  <#-- Annotations are only at document level -->
  <#if isDocument>
    <#return [{
      'sectionDoc': sectionDoc,
      'entityDocument': entityDocument,
      'sectionNode': sectionNode,
      'level': level
    }]>
  </#if>
  <#return []>
</#function>

<#-- Populates data table rows by calling querying IUCLID using runtime functions  -->
<#function populateAnnotationHash docHash>
  <#local sectionDoc = docHash.sectionDoc>
  <#local entityDocument = docHash.entityDocument>
  <#local sectionNode = docHash.sectionNode>
  <#local level = docHash.level>

  <#local sectionNumber = utils.getSectionNumber(sectionNode)>
  <#local populatedSeq = []>
  <#local annotationKeys = sectionDoc.annotations>
  <#if annotationKeys?has_content>
    <#-- Get the annotations of the document and map them to a template specific hash -->
    <#local sectionName = utils.getSectionName(sectionNode)>
    <#local sectionDocType = utils.getSectionDocType(sectionDoc)>
    <#local isActiveSubstanceOfRoot = false>
    <#local docUrl=utils.getDocumentUrl(sectionDoc)>
    <#list annotationKeys as key>
      <#local docHash = iuclid.getDocumentForKey(key)>
      <#local entityFunction = rootComponentsFunctionHash[key]!'' >
      <#local status =
      utils.getPicklistFieldAsText(docHash.AdminInfo.AnnotationStatus)>
      <#local confidentiality = utils.getConfidentialityFlag(docHash)>
      <#local agreement =
      utils.getPicklistFieldAsText(docHash.EvalInfo.AgreementWithApplicantsSummary)>
      <#local evalInfo = docHash.EvalInfo>
      <#local isWaiverable = utils.getPicklistFieldAsText(docHash.EvalInfo.DataWaiverAcceptable)>
      <#local reliability = utils.getPicklistFieldAsText(docHash.EvalInfo.Reliability)>
      <#local historyList = (utils.getFirstHistoryOnlyOfAnnotation(docHash)!'')>
      <#local annotationPopulated = {
        'annotation'              : docHash,
        'sectionDoc'              : sectionDoc,
        'sectionDocType'          : sectionDocType,
        'entityFunction'          : entityFunction,
        'sectionNode'             : sectionNode,
        'sectionName'             : sectionName,
        'sectionNumber'           : sectionNumber,
        'entityDocument'          : entityDocument,
        'docUrl'                  : docUrl,
        'key'                     : key,
        'status'                  : status,
        'confidentiality'         : confidentiality,
        'agreement'               : agreement,
        'evalInfo'                : evalInfo,
        'isWaiverable'            : isWaiverable,
        'reliability'             : reliability,
        'isActiveSubstanceOfRoot' : isActiveSubstanceOfRoot,
        'level'                   : level,
        'historyList'             : historyList
      }>
      <#local populatedSeq = populatedSeq + [annotationPopulated]>
    </#list>
  </#if>
  <#return populatedSeq>
</#function>

<#-- docID should be eg docKey; docID would be docKey.uuid -->
<#-- Maps data table annotation fields from IUCLID namespace to report specific -->
<#function annotationMapper annotation>
  <#local ah = annotation>
  <#return {
    FIELD.name                    : ah.annotation.AdminInfo.Name,
    FIELD.type                    : ah.annotation.AdminInfo.AnnotationType,
    FIELD.authority               : ah.annotation.AdminInfo.Authority,
    FIELD.dataProtection          : ah.annotation.AdminInfo.DataProtection,
    FIELD.docType                 : ah.annotation.documentType,
    FIELD.status                  : ah.status,
    FIELD.confidentiality         : ah.confidentiality,
    FIELD.agreement               : ah.agreement,
    FIELD.evalInfo                : ah.annotation.EvalInfo,
    FIELD.remarks                 : ah.annotation.EvalInfo.Remarks,
    FIELD.isWaiverable            : ah.annotation.EvalInfo.DataWaiverAcceptable,
    FIELD.entityName              : ah.entityDocument.name,
    FIELD.entityType              : ah.entityDocument.documentType,
    FIELD.entityID                : ah.entityDocument.documentKey,
    FIELD.entityDoc               : ah.entityDocument,
    FIELD.sectionNode             : ah.sectionNode,
    FIELD.sectionName             : ah.sectionName,
    FIELD.sectionNumber           : ah.sectionNumber,
    FIELD.sectionDocType          : ah.sectionDocType,
    FIELD.entityFunction          : ah.entityFunction,
    FIELD.docID                   : ah.sectionDoc.documentKey,
    FIELD.docUrl                  : ah.docUrl,
    FIELD.sectionDoc              : ah.sectionDoc,
    FIELD.sectionDocAnnots        : ah.sectionDoc.annotations,
    FIELD.key                     : ah.key,
    FIELD.reliability             : ah.reliability,
    FIELD.isActiveSubstanceOfRoot : ah.isActiveSubstanceOfRoot,
    FIELD.level                   : ah.level,
    FIELD.historyList             : ah.historyList
  }>
</#function>

<#assign
rootComponentsFunctionHash = utils.getComponentKeyToFunctionHash(rootSubject),
>

<#function createMixtureDataTables annotationSeq>
  <#local rootComponentAnnots = utils.filterIn(isInRootComponents, annotationSeq)>
  <#local activeSubstanceAnnots = utils.filterIn(isInActiveSubstances, annotationSeq)>
  <#return {
    'distantDescendantAnnots': utils.filterIn(isDistantDescendantAnnotation, annotationSeq),
    'activeSubstanceAnnots': activeSubstanceAnnots,
    'nonActiveSubstanceAnnots': utils.filterOut(isInActiveSubstances, rootComponentAnnots)
  }>
</#function>

<#function annotIsInComponentCollection annotation components>
  <#return components?seq_contains(annotation.entityID)>
</#function>

<#function isInActiveSubstances annotation><#-- TO_LAMBDA -->
  <#local rootActiveSubstanceKeys = utils.getActiveSubstanceKeyList(rootSubject)>
  <#return annotIsInComponentCollection(annotation, rootActiveSubstanceKeys)>
</#function>

<#function isInRootComponents annotation><#-- TO_LAMBDA -->
  <#local rootComponentKeys = utils.getComponentKeyList(rootSubject)>
  <#return annotIsInComponentCollection(annotation, rootComponentKeys)>
</#function>

<#function isDistantDescendantAnnotation annotation><#-- TO_LAMBDA -->
  <#local rootAndComponentDocumentKeys = rootComponentKeys + [rootSubject.documentKey]>
  <#return !(annotIsInComponentCollection(annotation, rootAndComponentDocumentKeys))>
</#function>

<#function isRootAnnotation annotation><#-- TO_LAMBDA -->
  <#return rootEntity.documentKey == annotation.entityID>
</#function>

<#assign docHashSeq = traversal.traverseAndCollect(rootEntity, collectDocumentHash)>
<#-- Depends rootComponentsFunctionHash definition in outer scope -->
<#assign annotationSeq = utils.mapcat(populateAnnotationHash, docHashSeq)>
<#assign dataTable = utils.map(annotationMapper, annotationSeq)>

<#if output_extension == "RTF">
  <#assign reportData = computeRtfReportData(dataTable)>
  <@layout_rtf.annotationsLayoutSubstance reportData rootType/>
<#elseif output_extension == "CSV">
  <#assign reportData = {SINGLETON_IND: {SINGLETON_IND: dataTable}}>
  <@layout_csv.produceReport reportData layoutMetadata/>
</#if>


<#function computeRtfReportData dataTable>
<#-- select() and filter() table data for report tables   -->
<#assign activeSubstanceAnnots = []>
<#assign nonActiveSubstanceAnnots = []>

<#assign mainAnnots = utils.filterIn(isRootAnnotation, dataTable)>
<#assign annotationSeqNotMain = utils.filterOut(isRootAnnotation, dataTable)>

<#-- Separation based on being active substance is relevant for mixture -->
<#if rootType==ENTITY.MIXTURE>
  <#assign dts = createMixtureDataTables(dataTable)>
  <#assign
    activeSubstanceAnnots = dts.activeSubstanceAnnots
    nonActiveSubstanceAnnots = dts.nonActiveSubstanceAnnots
    distantDescendantAnnots = dts.distantDescendantAnnots
  >
  <#assign mainDataTables = utils.groupBy(['entityName'], mainAnnots)>
  <#assign activeSubstanceDataTables = utils.groupBy(['entityName'], activeSubstanceAnnots)>
  <#assign nonActiveSubstanceDataTables = utils.groupBy(['entityName'], nonActiveSubstanceAnnots)>
  <#assign distantDescendantDataTables = {SINGLETON_IND: distantDescendantAnnots}>
  <#return computeOutlineDataMixture(
      rootName,
      mainDataTables,
      activeSubstanceDataTables,
      nonActiveSubstanceDataTables,
      distantDescendantDataTables
    )>
<#elseif rootType==ENTITY.SUBSTANCE>
  <#return computeOutlineDataSubstance(
    rootName,
    mainAnnots
  )>
</#if>
</#function>

<#function computeOutlineDataMixture
rootName
mainAnnots
activeSubstanceAnnots
nonActiveSubstanceAnnots
distantDescendantDataTables
>
  <#return computeOutlineData(
      ENTITY.MIXTURE,
      rootName,
      mainAnnots,
      activeSubstanceAnnots,
      nonActiveSubstanceAnnots,
      distantDescendantDataTables
    )
  >
</#function>

<#function computeOutlineDataSubstance rootName mainAnnots>
  <#return computeOutlineData(
    ENTITY.SUBSTANCE,
    rootName,
    mainAnnots,
    [],
    [],
    []
  )>
</#function>

<#function computeOutlineData
rootType
rootName
mainAnnots
activeSubstanceAnnots
nonActiveSubstanceAnnots
distantDescendantDataTables
>
  <#local mainAnnotData = {
    SECTION.ROOT: mainAnnots
  }>
  <#local outlineData = mainAnnotData>
  <#if rootType == 'SUBSTANCE'>
    <#return outlineData>
  </#if>
  <#if rootType == 'MIXTURE'>
    <#local componentAnnotData = {
        SECTION.ACTIVE: activeSubstanceAnnots,
        SECTION.NON_ACTIVE: nonActiveSubstanceAnnots,
        SECTION.DISTANT_DESCENDANTS: distantDescendantDataTables
      }>
    <#local outlineData = outlineData + componentAnnotData>
    <#return outlineData>
  </#if>
</#function>
