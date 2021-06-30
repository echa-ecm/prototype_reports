<#include '10_constants.ftl'>
<#import '20_utils.ftl' as utils>
<#import '30_traversal.ftl' as traversal>
<#import '40_layout.ftl' as layout>
<#import 'macros_common_general.ftl' as com>

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
    'name'                    : ah.annotation.AdminInfo.Name,
    'type'                    : ah.annotation.AdminInfo.AnnotationType,
    'authority'               : ah.annotation.AdminInfo.Authority,
    'dataProtection'          : ah.annotation.AdminInfo.DataProtection,
    'docType'                 : ah.annotation.documentType,
    'status'                  : ah.status,
    'confidentiality'         : ah.confidentiality,
    'agreement'               : ah.agreement,
    'evalInfo'                : ah.annotation.EvalInfo,
    'remarks'                 : ah.annotation.EvalInfo.Remarks,
    'isWaiverable'            : ah.annotation.EvalInfo.DataWaiverAcceptable,
    'entityName'              : ah.entityDocument.name,
    'entityType'              : ah.entityDocument.documentType,
    'entityID'                : ah.entityDocument.documentKey,
    'entityDoc'               : ah.entityDocument,
    'sectionNode'             : ah.sectionNode,
    'sectionName'             : ah.sectionName,
    'sectionNumber'           : ah.sectionNumber,
    'sectionDocType'          : ah.sectionDocType,
    'entityFunction'          : ah.entityFunction,
    'docID'                   : ah.sectionDoc.documentKey,
    'docUrl'                  : ah.docUrl,
    'sectionDoc'              : ah.sectionDoc,
    'sectionDocAnnots'        : ah.sectionDoc.annotations,
    'key'                     : ah.key,
    'reliability'             : ah.reliability,
    'isActiveSubstanceOfRoot' : ah.isActiveSubstanceOfRoot,
    'level'                   : ah.level,
    'historyList'             : ah.historyList
  }>
</#function>

<#-- TODO remove necessity to define these outer scope variables for map/filter sequence functions -->
<#assign
rootComponentsFunctionHash = utils.getComponentKeyToFunctionHash(rootSubject),
rootActiveSubstanceKeys = utils.getActiveSubstanceKeyList(rootSubject),
rootComponentKeys = utils.getComponentKeyList(rootSubject)

rootAndComponentDocumentKeys = rootComponentKeys + [rootSubject.documentKey]>

<#function createMixtureDataTables annotationSeq>
  <#local rootComponentAnnots = utils.filterIn(isInRootComponents, annotationSeq)>
  <#local activeSubstanceAnnots = utils.filterIn(isInActiveSubstances, annotationSeq)>
  <#return {
    'distantDescendantAnnots': utils.filterIn(isDistantDescendantAnnotation, annotationSeq),
    'activeSubstanceAnnots': activeSubstanceAnnots,
    'nonActiveSubstanceAnnots': utils.filterOut(isInActiveSubstances, rootComponentAnnots)
  }>
</#function>

<#function isInActiveSubstances annotation><#-- TO_LAMBDA -->
  <#return rootActiveSubstanceKeys?seq_contains(annotation.entityID)>
</#function>

<#function isInRootComponents annotation><#-- TO_LAMBDA -->
  <#return rootComponentKeys?seq_contains(annotation.entityID)>
</#function>

<#function isDistantDescendantAnnotation annotation><#-- TO_LAMBDA -->
  <#return !(rootAndComponentDocumentKeys?seq_contains(annotation.entityID))>
</#function>

<#function isRootAnnotation annotation><#-- TO_LAMBDA -->
  <#return rootEntity.documentKey == annotation.entityID>
</#function>

<#assign docHashSeq = traversal.traverseAndCollect(rootEntity, collectDocumentHash)>
<#-- Depends rootComponentsFunctionHash definition in outer scope -->
<#assign annotationSeq = utils.mapcat(populateAnnotationHash, docHashSeq)>
<#assign annotationSeq = utils.map(annotationMapper, annotationSeq)>

<#-- select() and filter() table data for report tables   -->
<#assign activeSubstanceAnnots = []>
<#assign nonActiveSubstanceAnnots = []>

<#assign mainAnnots = utils.filterIn(isRootAnnotation, annotationSeq)>
<#assign annotationSeqNotMain = utils.filterOut(isRootAnnotation, annotationSeq)>

<#-- Separation based on being active substance is relevant for mixture -->
<#if rootType==ENTITY.MIXTURE>
  <#assign dts = createMixtureDataTables(annotationSeq)>
  <#assign
    activeSubstanceAnnots = dts.activeSubstanceAnnots
    nonActiveSubstanceAnnots = dts.nonActiveSubstanceAnnots
    distantDescendantAnnots = dts.distantDescendantAnnots
  >
  <#assign mainDataTables = utils.groupBy(['entityName'], mainAnnots)>
  <#assign activeSubstanceDataTables = utils.groupBy(['entityName'], activeSubstanceAnnots)>
  <#assign nonActiveSubstanceDataTables = utils.groupBy(['entityName'], nonActiveSubstanceAnnots)>
  <#assign distantDescendantDataTables = {SINGLETON_IND: distantDescendantAnnots}>
  <#assign reportData =
    computeOutlineDataMixture(
      rootName,
      mainDataTables,
      activeSubstanceDataTables,
      nonActiveSubstanceDataTables,
      distantDescendantDataTables
    )>
  <@layout.annotationsLayoutMixture reportData rootType/>
<#elseif rootType==ENTITY.SUBSTANCE>
  <#assign reportData =
  computeOutlineDataSubstance(
    rootName,
    mainAnnots
  )>
  <@layout.annotationsLayoutSubstance reportData ENTITY.SUBSTANCE/>
</#if>

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


