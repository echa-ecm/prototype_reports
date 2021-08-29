<#include '10_constants.ftl'>
<#import '30_utils.ftl' as utils>
<#import '40_traversal.ftl' as traversal>
<#import '50_layout.ftl' as layout>

<#assign rootEntity = entity.root>
<#assign rootName = rootDocument.name>

<#-- Function called during traversal for creating seq of nodes relevant to the report  -->
<#function collectHashSeq elementNode entityDocument sectionNode level>
  <#if elementNode?node_type == 'document'>
    <#local docHash = {
      'elementNode': elementNode,
      'entityDocument': entityDocument,
      'sectionNode': sectionNode,
      'level': level
    }>
     <#return [docHash]>
  </#if>
  <#return []>
</#function>

<#-- Should resemble IUCLID data schema as closely as possible
  Completes/populates data table row entries by 1. querying
  IUCLID using runtime functions (prefix underline) or 2. accessing document node data -->
<#function populateDocHash docHash>
  <#local sectionName = utils.getSectionName(docHash.sectionNode)>
  <#local level = docHash.level>
  <#-- Get populate fields and map them to a template specific hash -->
  <#local populatedDocHash = {
    'elementNode'    : docHash.elementNode,
    'level'          : level,
    'entityDocument' : docHash.entityDocument,
    'sectionName'    : sectionName
  }>
  <#return populatedDocHash>
</#function>

<#-- documentKey should be eg docKey; documentKey would be docKey.uuid -->
<#-- Maps data table annotation fields from IUCLID namespace to report specific -->
<#function mapDocHash populatedDocHash>
  <#local pdh = populatedDocHash>
  <#return {
    FIELD.nodeType    : pdh.elementNode?node_type,
    FIELD.level       : pdh.level,
    FIELD.entityName  : pdh.entityDocument.name,
    FIELD.sectionName : pdh.sectionName,
    FIELD.nodeName    : pdh.elementNode.name
  }>
</#function>

<#assign dataTable = traversal.traverseAndCollect(rootEntity, collectHashSeq)>

<#-- Depends rootComponentsFunctionHash definition in outer scope -->
<#assign dataTable = utils.map(populateDocHash, dataTable)>
<#assign dataTable = utils.map(mapDocHash, dataTable)>

<#---------------------------------------------------->
<#-- Examples of sequence functions:------------------>
<#---(Un)comment lines to experiment with functions--->
<#---------------------------------------------------->

<#-- 1. map({{function}}, {{sequence}}): capitalize node types -->

<#--
<#function uppercaseNodeType docHash>
  <#return docHash + {FIELD.nodeType: docHash[FIELD.nodeType]?upper_case}>
</#function>
<#assign dataTable = utils.map(uppercaseNodeType, dataTable)>
-->

<#-- 2. filter({{function}}, {{data table}}): select rows where function evaluates to `true` -->

<#-- 
<#function belongsToSubstance docHash>
<#return docHash[FIELD.sectionName] == 'Substance'>
</#function>
<#assign dataTable = utils.filter(belongsToSubstance, dataTable)>
-->

<#-- 3. group_by({{sequence of keys}}, {{data table}}): split table by key value-->
<#-- The example has the same effect as filter -->

<#--
<#assign byNodeTypeGroups = utils.groupBy([FIELD.sectionName], dataTable)>
<#assign dataTable = byNodeTypeGroups['Substance']>
-->

<#-- 4. select({{sequence of keys}}, {{data table}}): reorder/select columns of data table -->

<#--
<#assign dataTable = utils.select([FIELD.sectionName, FIELD.entityName], dataTable)>
-->


<#--------------------->
<#-- End of Examples -->
<#--------------------->


<#-- encapsulate sole data table to fulfill layout.produceReport macro requirements (common to list reports)-->
<#assign reportData = {SINGLETON_CHAPTER: {SINGLETON_TABLE: dataTable}}>

<#-- No metadata is required to produce csv files. -->
<#assign layoutMetadata = {}>
<#-- HOWEVER selecting columns in a specific order is supported -->
<#-- <#assign layoutMetadata = {'columnsOrdered': [FIELD.sectionName, FIELD.entityName]}> -->
<@layout.produceReport reportData=reportData metadata=layoutMetadata/>
