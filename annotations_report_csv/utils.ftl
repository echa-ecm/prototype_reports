<#function filter fun seq>
  <#local filtered = []>
  <#list seq as item>
    <#if fun(item)>
      <#local filtered = filtered + [item]>
    </#if>
  </#list>
  <#return filtered>
</#function>

<#-- Prints the textToken nr number of times -->
<#function getIndentationText nr textToken = "-">
  <#local indentText = "">
  <#list 1..nr as x>
    <#local indentText = indentText + textToken>
  </#list>
  <#return indentText>
</#function>

<#function addDocumentToSequenceAsUnique document sequence>
  <#if !(document?has_content)>
    <#return sequence>
  </#if>
  <#list sequence as doc>
    <#if document.documentKey == doc.documentKey>
      <#return sequence>
    </#if>
  </#list>
  <#return sequence + [document]>
</#function>

<#-- Gets a docSequence list of documents and a docKeyList list of keys. Returns a new list of documents that contain only those document whose keys did not appear in docKeyList -->
<#function removeDocumentWitKey docSequence docKeyList>
  <#if !(docSequence?has_content && docKeyList?has_content)>
    <#return docSequence>
  </#if>
  <#local newSequence = []>
  <#list docSequence as doc>
    <#if !(docKeyList?seq_contains(doc.documentKey))>
      <#local newSequence = newSequence + [doc]>
    </#if>
  </#list>
  <#return newSequence>
</#function>

<#-- Function to check if the docElementNode element node is a reference field and remember referenced entities
   for later traversal
   toTravereseList - a list with already identified entity documents for traversal
   traveresedKeyList - a list with document keys already traversed
   returns a new version of the toTravereseList -->
<#function checkAndRememberReferencedEntity docElementNode toTravereseList traveresedKeyList>
  <#if docElementNode?node_type == "document_reference">
    <#return checkAndRememberEntityKey(docElementNode, toTravereseList, traveresedKeyList) />
  </#if>
  <#if docElementNode?node_type == "document_references">
    <#local newToTraverseList = toTravereseList>
    <#list docElementNode as item>
      <#local newToTraverseList = checkAndRememberEntityKey(item, newToTraverseList, traveresedKeyList) />
    </#list>
    <#return newToTraverseList />
  </#if>
  <#return toTravereseList>
</#function>

<#-- Function to check whether the docKey is a refrence to an entity document and if it was not traversed yet,
  remember it for later traversal by returning a new list based on toTravereseEntityList
  toTravereseList - a list with already identified entity documents for traversal
  traveresedKeyList - a list with document keys already traversed
  returns a new version of the toTravereseList -->
<#function checkAndRememberEntityKey docKey toTravereseList traveresedKeyList>
  <#local doc = iuclid.getDocumentForKey(docKey) />
  <#if doc?has_content && utils.isEntityDocument(doc) && !(traveresedKeyList?seq_contains(doc.documentKey))>
      <#return utils.addDocumentToSequenceAsUnique(doc, toTravereseList)>
  </#if>
  <#return toTravereseList>
</#function>

<#-- List of IUCLID's entity types -->
<#assign entityTypes = ["SUBSTANCE", "MIXTURE", "TEMPLATE", "ANNOTATION", "ARTICLE", "CATEGORY", "CONTACT", "LEGAL_ENTITY", "LITERATURE", "REFERENCE_SUBSTANCE", "SITE", "TEST_MATERIAL_INFORMATION"]>

<#-- Returns true if doc is a IUCLID entity -->
<#function isEntityDocument doc>
  <#return entityTypes?seq_contains(doc.documentType)>
</#function>

<#-- List of IUCLID's composite entity types -->
<#assign compositeEntityTypes = ["SUBSTANCE", "MIXTURE", "TEMPLATE"]>

<#-- Returns true if doc is a IUCLID composite entity -->
<#function isCompositeEntityDocument doc>
  <#return compositeEntityTypes?seq_contains(doc.documentType)>
</#function>

<#function getInheritedTemplates entityDoc>
  <#--
  <#if !(mode?has_content && mode == "PUBLISHING") && entityDoc.documentType == "SUBSTANCE">
    <#return entityDoc.inherited>
  </#if>
  -->
  <#return []>
</#function>

<#function getRelatedCategories entityDoc>
  <#if !(mode?has_content && mode == "PUBLISHING")>
    <#local params={"key": [entityDoc.documentKey]}>
    <#return iuclid.query("iuclid6.SubstanceRelatedCategories", params, 0, 100)>
  </#if>
	<#return []>
</#function>

<#function getRelatedMixtures entityDoc>
  <#--
  <#if !(mode?has_content && mode == "PUBLISHING")>
    <#local params={"key": [entityDoc.documentKey]}>
    <#return iuclid.query("iuclid6.SubstanceRelatedMixtures", params, 0, 100)>
  </#if>
   -->
	<#return []>
</#function>

<#-- Function that recieves a text value as input and return a new string escaped for .csv file (comma separated value)
  It replaces in the text every quotes (") character with two quotes ("")
  It puts the text into a "<text>" format -->
<#function escapeCsvText textValue>
  <#if !(textValue?has_content)>
    <#-- Return "" -->
    <#return "\"\"">
  </#if>
  <#local newValue = textValue>
  <#local newValue = newValue?replace("\"", "\"\"")>
  <#local newValue = newValue?replace("\n", "\\n")>
  <#return "\""+ newValue + "\"">
</#function>

<#-- Macro that prints the textValue in a csv escaped format -->
<#macro csvValue textValue>
<#compress>
${escapeCsvText(textValue)}
</#compress>
</#macro>

<#function getDocumentUrl document>
  <#local generatedUrl = iuclid.webUrl.entityView(document.documentKey) />
  <#if generatedUrl?has_content>
    <#-- Get the base URL part -->
    <#local generatedUrl = generatedUrl?keep_before("/iuclid6-web") />
  </#if>
  <#return generatedUrl + "/iuclid6-web/?key=" + document.documentKey>
</#function>

<#function getPicklistFieldAsText picklistValue includeDescription=false locale="en">
  <#if !picklistValue?has_content>
    <#return ""/>
  </#if>
  <#local localizedPhrase = iuclid.localizedPhraseDefinitionFor(picklistValue.code, locale) />
  <#if !localizedPhrase?has_content>
    <#return ""/>
  </#if>
  <#local displayText = localizedPhrase.text />
  <#if localizedPhrase.open && picklistValue.otherText?has_content>
    <#local displayText = displayText + " " + picklistValue.otherText />
  </#if>
  <#if includeDescription && localizedPhrase.description?has_content>
    <#local displayText = displayText + " [" + localizedPhrase.description + "]" />
  </#if>
  <#return displayText>
</#function>

<#function getSectionName sectionNode>
  <#local sectionName = "">
  <#if sectionNode?has_content>
    <#if sectionNode.number?has_content>
      <#local sectionName = sectionNode.number + " ">
    </#if>
    <#local sectionName = sectionName + sectionNode.title>
  </#if>
  <#return sectionName>
</#function>

<#function getSectionDocType sectionDoc>
  <#local sectionDocType = sectionDoc.documentType>
  <#if !utils.isEntityDocument(sectionDoc)>
    <#local sectionDocType = sectionDocType + "." + sectionDoc.documentSubType>
  </#if>
  <#return sectionDocType>
</#function>

<#-- deprecated with lambdas in Freemarker 2.3.29 -->
<#function filterByKeyValue key value seq>
  <#local filtered = []/>
  <#list seq as hashElement>
    <#if hashElement[key] == value>
      <#local filtered = filtered + [hashElement] >
    </#if>
  </#list>
  <#return filtered>
</#function>

<#function groupByKey key seq>
  <#local groupsHash = {}>
  <#list seq as hashEl>
    <#local elVal = hashEl[key]>
    <#local keyGroup = groupsHash[elVal]![] + [hashEl]>
    <#local groupsHash = groupsHash + {elVal: keyGroup}>
  </#list>
  <#local groups = [] >
  <#return groupsHash>
</#function>

<#function map fun seq>
    <#local mapped = []>
    <#list seq as item>
        <#local mapped = mapped + [fun(item)]>
    </#list>
    <#return mapped>
</#function>

<#function mapcat fun seq>
    <#local mapped = []>
    <#list seq as item>
        <#local mapped = mapped + fun(item)>
    </#list>
    <#return mapped>
</#function>
