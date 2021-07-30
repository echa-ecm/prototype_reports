<#assign rootEntity = entity.root>
<#assign DEFAULT_MAX_LOOP=5>

<#function traverseAndCollect rootEntity documentCollectorFun maxLoop=''>
  <#-- Utility list to remember tarversed entities -->
  <#assign traversedEntityKeyList = [rootEntity.documentKey]>
  <#assign documentCollectorFun = documentCollectorFun>
  <#local actualMaxLoop = maxLoop>
  <#if !(actualMaxLoop?has_content)>
    <#local actualMaxLoop = DEFAULT_MAX_LOOP>
  </#if>
  <#-- Utility list to remember entities yet to be traversed -->
  <#assign toTraverseEntityList = []>
  <#-- Traverse the main entity -->
  <#local rootNodeHashes = traverseEntity(rootEntity, [])/>
  <#-- Sequence for storing annotation entries of form: [{'key1': 'value1'}, {'key2': 'value2'}] -->
  <#local docHashSeq = rootNodeHashes>
  <#-- Go throught the found referenced entities and traverse them. NOTE: the list can grow further as entities can reference further entities. Unclear whether this works well in FreeMarker -->
  <#-- FreeMarker does not support do-while loops as such do this workaround with maxLoop -->
  <#list 1..actualMaxLoop as x>
    <#-- Remove documents that have been already traversed -->
    <#assign toTraverseEntityList = utils.removeDocumentWitKey(
      toTraverseEntityList,
      traversedEntityKeyList
    )>
    <#if !(toTraverseEntityList?has_content)>
      <#-- Stop looping if there is nothing to traverse -->
    <#break>
    </#if>
    <#-- Traverse each entity from the list -->
    <#list toTraverseEntityList as entityItem>
      <#assign traversedEntityKeyList =
      traversedEntityKeyList + [entityItem.documentKey]>
      <#local docHashSeq = traverseEntity(entityItem, docHashSeq)/>
    </#list>
  </#list>
  <#return docHashSeq>
</#function>

<#----------------------------------------------->
<#-- Macro and function definitions start here -->
<#----------------------------------------------->

<#function traverseEntity entityDoc docHashSeq>
  <#if utils.isCompositeEntityDocument(entityDoc)>
    <#return traverseCompositeEntity(entityDoc docHashSeq)/>
  <#else>
    <#return traverseSimpleEntity(entityDoc docHashSeq)/>
  </#if>
</#function>

<#function traverseSimpleEntity entityDoc docHashSeq>
  <#return traverseDoc(entityDoc entityDoc docHashSeq 0)/>
</#function>

<#function traverseCompositeEntity entityDoc docHashSeq>
  <#local tableOfContents=iuclid.localizeTreeFor(
    entityDoc.documentType,
    entityDoc.submissionType,
    entityDoc.documentKey,
    utils.getInheritedTemplates(entityDoc),
    utils.getRelatedCategories(entityDoc),
    utils.getRelatedMixtures(entityDoc)
  )>
  <#return traverseToc(tableOfContents entityDoc docHashSeq 0)/>
</#function>

<#function traverseDoc
docElementNode
entityDocument
docHashSeq
level=0
sectionNode=''
isDocument=true>
  <#local newDocHashSeq = docHashSeq>
  <#if docElementNode?has_content>
    <#-- Annotations are only at document level -->
    <#local newDocHashSeq = docHashSeq + documentCollectorFun(
      docElementNode, entityDocument, sectionNode, level
    )>
    <#-- Check if the element node is a reference field (single or multiple) and remember referenced entities for later traversal in toTraverseEntityList -->
    <#assign toTraverseEntityList = utils.checkAndRememberReferencedEntity(
      docElementNode,
      toTraverseEntityList,
      traversedEntityKeyList
    ) />
    <#-- iterate through the child structure elements of this document element if there are any and do a recursive call -->
    <#if docElementNode?children?has_content>
      <#list docElementNode?children as child>
        <#-- sequence remains unchanged as `traverseDoc' is called for entityDiscover side-effect -->
        <#local newDocHashSeq = traverseDoc(
          child
          entityDocument
          newDocHashSeq
          level+1
          sectionNode
          false) >
      </#list>
    </#if>
  </#if>
  <#return newDocHashSeq/>
</#function>

<#function traverseToc sectionNode entityDocument docHashSeq level=0>
  <#local newDocHashSeq = docHashSeq/>
  <#if sectionNode?has_content>
    <#-- iterate through the section documents under this section if there are any -->
    <#if sectionNode.content?has_content>
      <#list sectionNode.content as doc>
        <#-- traverse through the document's blocks and fields aka elements -->
        <#local newDocHashSeq = traverseDoc(doc entityDocument newDocHashSeq level+1 sectionNode )/>
      </#list>
    </#if>
    <#-- iterate through the child sections of the node and do a recursive call -->
    <#if sectionNode?children?has_content>
      <#list sectionNode?children as child>
        <#local newDocHashSeq = traverseToc(child entityDocument newDocHashSeq level+1 )/>
      </#list>
    </#if>
  </#if>
  <#return newDocHashSeq/>
</#function>
