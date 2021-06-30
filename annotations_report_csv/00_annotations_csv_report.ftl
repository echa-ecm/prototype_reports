<#import "traversal_utils.ftl" as traversal>
<#import "utils.ftl" as utils>
<#assign rootEntity = entity.root>

<#macro printCsvHeadersRow>
  "Annotation name",<#t>
  "Annotation status",<#t>
  "Annotation - Agreement with applicant",<#t>
  "Annotation - Evaluation remarks",<#t>
  "Entity name",<#t>
  "Entity type",<#t>
  "Entity UUID",<#t>
  "TOC Section name",<#t>
  "Section document name",<#t>
  "Section document type",<#t>
  "Section document UUID",<#t>
  "URL"<#t>
</#macro>
<#assign reportFieldProperties = {
  'name'           : {"isFormatted": true},
  'status'         : {"isFormatted": true},
  'agreement'      : {"isFormatted": true},
  'remarks'        : {"isFormatted": true},
  'docName'        : {"isFormatted": true},
  'entityType'     : {"isFormatted": false},
  'entityID'       : {"isFormatted": false},
  'section'        : {"isFormatted": true},
  'sectionDocName' : {"isFormatted": true},
  'sectionDocType' : {"isFormatted": false},
  'docID'          : {"isFormatted": false},
  'docUrl'         : {"isFormatted": true}
}>

<#function populateAnnotationHash annotationHash>
  <#local sectionDoc = annotationHash.sectionDoc>
  <#local entityDocument = annotationHash.entityDocument>
  <#local sectionNode = annotationHash.sectionNode>
  <#local annotationKeys = sectionDoc.annotations>
  <#local level = annotationHash.level>
  <#local populatedSeq = []>
  <#if annotationKeys?has_content>
    <#-- Get the annotations of the document and map them to a template specific hash -->
    <#local sectionName = utils.getSectionName(sectionNode)>
    <#local sectionDocType = utils.getSectionDocType(sectionDoc)>
    <#--     <#local isActiveSubstance = isActiveSubstance(entityDocument.documentKey)> -->
    <#local isActiveSubstance = true>
    <#local docUrl=utils.getDocumentUrl(sectionDoc)>
    <#list annotationKeys as annotationKey>
      <#local annotation = iuclid.getDocumentForKey(annotationKey)>
      <#local annotationStatus =
        utils.getPicklistFieldAsText(annotation.AdminInfo.AnnotationStatus)>
      <#local annotationAgreement =
        utils.getPicklistFieldAsText(annotation.EvalInfo.AgreementWithApplicantsSummary)>
      <#local annotationPopulated = {
        "annotation": annotation,
        "sectionDoc": sectionDoc,
        "sectionDocType": sectionDocType,
        "sectionName": sectionName,
        "entityDocument": entityDocument,
        "docUrl": docUrl,
        "annotationKey": annotationKey,
        "annotationStatus": annotationStatus,
        "annotationAgreement": annotationAgreement,
        "isActiveSubstance": isActiveSubstance,
        "level": level
        }>
      <#local populatedSeq = populatedSeq + [annotationPopulated]>
    </#list>
  </#if>
  <#return populatedSeq>
</#function>

<#function collectDocumentHash sectionDoc entityDocument sectionNode level>
  <#return {
    "entityDocument": entityDocument,
    "sectionDoc": sectionDoc,
    "sectionNode": sectionNode,
    "level": level
  }>
</#function>

<#function annotationMapper annotationHash>
  <#local ah = annotationHash>
  <#return {
    'name'              : ah.annotation.AdminInfo.Name,
    'type'              : ah.annotation.AdminInfo.AnnotationType,
    'dataProtection'    : ah.annotation.AdminInfo.DataProtection,
    'status'            : ah.annotationStatus,
    'agreement'         : ah.annotationAgreement,
    'remarks'           : ah.annotation.EvalInfo.Remarks,
    'docName'           : ah.entityDocument.name,
    'entityType'        : ah.entityDocument.documentType,
    'entityID'          : ah.entityDocument.documentKey,
    'section'           : ah.sectionName,
    'sectionDocName'    : ah.sectionDoc.name,
    'sectionDocType'    : ah.sectionDocType,
    'docID'             : ah.sectionDoc.documentKey,
    'docUrl'            : ah.docUrl,
    'sectionDoc'        : ah.sectionDoc,
    'sectionDocAnnots'  : ah.sectionDoc.annotations,
    'key'               : ah.annotationKey,
    'isActiveSubstance' : ah.isActiveSubstance,
    'level': ah.level
  }>
</#function>

<#-- TODO add check that reportFieldProperties correspond to annotation mapper parameters -->
<#-- generate from template? -->
<#assign docHashSeq = traversal.traverseAndCollect(rootEntity, collectDocumentHash)>

<#assign annotationSeq = utils.mapcat(populateAnnotationHash, docHashSeq)>
<#assign annotationSeq = utils.map(annotationMapper, annotationSeq)>
<@printCsvHeadersRow/>

<#macro writeRow annotation>
  <#local fields=[]>
  <#list reportFieldProperties?keys as field>
    <#local fields = fields + [formatValue(annotation, field)!""]>
  </#list>
  ${fields?join(",")}<#t>
</#macro>

<#function formatValue annotation key>
  <#if annotation[key]?? && reportFieldProperties[key].isFormatted >
      <#return utils.escapeCsvText(annotation[key])>
    <#else>
      <#return annotation[key]>
    </#if>
</#function>
<#t>
<#list annotationSeq as annotation>
  <@writeRow annotation/>

</#list>
